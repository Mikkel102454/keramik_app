package nu.miguel.claydock

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.android.billingclient.api.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Play owns eligibility, mandatory disclosures, parental controls and billing choice UI. */
class ClayDockBilling(private val activity: Activity, private val channel: MethodChannel) {
    private var client: BillingClient? = null
    private var mode = "PLAY"
    private val handler = Handler(Looper.getMainLooper())
    private var pendingPurchase: MethodChannel.Result? = null
    private val products = mutableMapOf<String, ProductDetails>()
    private var externalToken: String? = null

    init { channel.setMethodCallHandler(::handle) }

    private fun program(value: String): Int? = when(value) {
        "EXTERNAL_CONTENT_LINK" -> BillingClient.BillingProgram.EXTERNAL_CONTENT_LINK
        "EXTERNAL_OFFERS" -> BillingClient.BillingProgram.EXTERNAL_OFFER
        "BILLING_CHOICE" -> BillingClient.BillingProgram.BILLING_CHOICE
        "EXTERNAL_PAYMENTS" -> BillingClient.BillingProgram.EXTERNAL_PAYMENTS
        else -> null
    }

    private fun fail(result: MethodChannel.Result, code: String = "BILLING_UNAVAILABLE") {
        result.error(code, "Purchasing is unavailable. Please retry.", null)
    }

    private fun connect(requestedMode: String, result: MethodChannel.Result, block: (BillingClient) -> Unit) {
        if (requestedMode !in listOf("PLAY", "EXTERNAL_CONTENT_LINK", "EXTERNAL_OFFERS", "BILLING_CHOICE", "EXTERNAL_PAYMENTS")) { fail(result); return }
        if (client?.isReady == true && mode == requestedMode) { block(client!!); return }
        client?.endConnection(); products.clear(); externalToken = null; mode = requestedMode
        val builder = BillingClient.newBuilder(activity).setListener { response, purchases ->
            val waiting = pendingPurchase; pendingPurchase = null
            if (waiting != null) {
                if (response.responseCode == BillingClient.BillingResponseCode.OK) waiting.success(purchases?.map(::purchase) ?: emptyList<Map<String, Any>>())
                else if (response.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) waiting.success(mapOf("canceled" to true))
                else fail(waiting)
            }
            // Deliver recovered/late purchase events; Dart always sends tokens to authenticated verification.
            if (response.responseCode == BillingClient.BillingResponseCode.OK && waiting == null)
                channel.invokeMethod("purchases", purchases?.map(::purchase) ?: emptyList<Map<String, Any>>())
        }.enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().enablePrepaidPlans().build())
        program(requestedMode)?.let { value ->
            val params = EnableBillingProgramParams.newBuilder().setBillingProgram(value)
            if (requestedMode == "BILLING_CHOICE" || requestedMode == "EXTERNAL_PAYMENTS") {
                params.setDeveloperProvidedBillingListener { details ->
                    val waiting = pendingPurchase; pendingPurchase = null
                    waiting?.success(mapOf("external" to true, "externalTransactionToken" to details.externalTransactionToken))
                }
            }
            builder.enableBillingProgram(params.build())
        }
        val created = builder.build(); client = created
        created.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(response: BillingResult) {
                if (response.responseCode == BillingClient.BillingResponseCode.OK) block(created) else fail(result)
            }
            override fun onBillingServiceDisconnected() { /* Each operation reconnects; no implicit purchase retry. */ }
        })
    }

    private fun purchase(value: Purchase): Map<String, Any> = mapOf(
        "purchaseToken" to value.purchaseToken, "purchased" to (value.purchaseState == Purchase.PurchaseState.PURCHASED),
        "pending" to (value.purchaseState == Purchase.PurchaseState.PENDING))

    private fun available(billing: BillingClient, result: MethodChannel.Result, block: () -> Unit) {
        val value = program(mode)
        if (value == null) { block(); return }
        billing.isBillingProgramAvailableAsync(value) { response, details ->
            if (response.responseCode != BillingClient.BillingResponseCode.OK) { fail(result); return@isBillingProgramAvailableAsync }
            if (mode == "BILLING_CHOICE") {
                val choice = details.billingChoiceAvailabilityDetails
                if (choice == null || !choice.isExternalLinkAvailable || choice.choiceScreenType != BillingProgramAvailabilityDetails.BillingChoiceAvailabilityDetails.ChoiceScreenType.GOOGLE_RENDERED) {
                    fail(result); return@isBillingProgramAvailableAsync
                }
            }
            block()
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "country" -> connect("PLAY", result) { billing ->
                billing.getBillingConfigAsync(GetBillingConfigParams.newBuilder().build()) { response, config ->
                    if (response.responseCode == BillingClient.BillingResponseCode.OK && config != null) result.success(config.countryCode) else fail(result)
                }
            }
            "offers" -> connect(call.argument<String>("mode") ?: "PLAY", result) { billing ->
                available(billing, result) {
                    if (mode == "EXTERNAL_CONTENT_LINK" || mode == "EXTERNAL_OFFERS") { result.success(emptyList<Map<String, Any>>()); return@available }
                    val ids = call.argument<List<String>>("productIds") ?: emptyList()
                    val params = QueryProductDetailsParams.newBuilder().setProductList(ids.distinct().map {
                        QueryProductDetailsParams.Product.newBuilder().setProductId(it).setProductType(BillingClient.ProductType.SUBS).build()
                    }).build()
                    billing.queryProductDetailsAsync(params) { response, details ->
                        if (response.responseCode != BillingClient.BillingResponseCode.OK) { fail(result); return@queryProductDetailsAsync }
                        products.clear()
                        val offers = details.productDetailsList.flatMap { product ->
                            products[product.productId] = product
                            product.subscriptionOfferDetails?.map { offer ->
                                mapOf("productId" to product.productId, "basePlanId" to offer.basePlanId,
                                    "offerToken" to offer.offerToken, "name" to product.name,
                                    "phases" to offer.pricingPhases.pricingPhaseList.map { phase ->
                                        mapOf("price" to phase.formattedPrice, "currency" to phase.priceCurrencyCode,
                                            "period" to phase.billingPeriod, "cycles" to phase.billingCycleCount)
                                    })
                            } ?: emptyList()
                        }
                        result.success(offers)
                    }
                }
            }
            "reportingToken" -> connect(call.argument<String>("mode") ?: "", result) { billing ->
                available(billing, result) {
                    val value = program(mode)
                    if (value == null) { fail(result); return@available }
                    val params = BillingProgramReportingDetailsParams.newBuilder().setBillingProgram(value)
                    if (mode == "BILLING_CHOICE") params.setDeveloperBillingType(BillingProgramReportingDetailsParams.DeveloperBillingType.EXTERNAL_LINK)
                    billing.createBillingProgramReportingDetailsAsync(params.build()) { response, details ->
                        if (response.responseCode == BillingClient.BillingResponseCode.OK && !details?.externalTransactionToken.isNullOrBlank()) {
                            externalToken = details!!.externalTransactionToken; result.success(externalToken)
                        } else fail(result)
                    }
                }
            }
            "purchase" -> {
                val billing = client
                val id = call.argument<String>("productId")
                val offerToken = call.argument<String>("offerToken")
                val product = products[id]
                if (billing?.isReady != true || product == null || offerToken == null || pendingPurchase != null) { fail(result); return }
                available(billing, result) {
                    val params = BillingFlowParams.newBuilder().setObfuscatedAccountId(call.argument<String>("accountId") ?: "")
                        .setProductDetailsParamsList(listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(product).setOfferToken(offerToken).build()))
                    if (mode == "BILLING_CHOICE" || mode == "EXTERNAL_PAYMENTS") {
                        val destination = call.argument<String>("destination")
                        if (destination.isNullOrBlank() || externalToken.isNullOrBlank() || Uri.parse(destination).scheme != "https") { fail(result); return@available }
                        params.enableDeveloperBillingOption(DeveloperBillingOptionParams.newBuilder().setBillingProgram(program(mode)!!)
                            .setExternalTransactionToken(externalToken!!).setLinkUri(Uri.parse(destination))
                            .setLaunchMode(DeveloperBillingOptionParams.LaunchMode.LAUNCH_IN_EXTERNAL_BROWSER_OR_APP).build())
                    }
                    pendingPurchase = result
                    val response = billing.launchBillingFlow(activity, params.build()); externalToken = null
                    if (response.responseCode != BillingClient.BillingResponseCode.OK) { pendingPurchase = null; fail(result) }
                    handler.postDelayed({ if (pendingPurchase === result) { pendingPurchase = null; fail(result, "BILLING_TIMEOUT") } }, 120000)
                }
            }
            "externalLink" -> {
                val billing = client; val value = program(mode); val destination = call.argument<String>("destination")
                if (billing?.isReady != true || value == null || destination.isNullOrBlank() || externalToken.isNullOrBlank() || Uri.parse(destination).scheme != "https") { fail(result); return }
                available(billing, result) {
                    val params = LaunchExternalLinkParams.newBuilder().setBillingProgram(value).setLinkUri(Uri.parse(destination))
                        .setExternalTransactionToken(externalToken!!).setLinkType(LaunchExternalLinkParams.LinkType.LINK_TO_DIGITAL_CONTENT_OFFER)
                        .setLaunchMode(LaunchExternalLinkParams.LaunchMode.LAUNCH_IN_EXTERNAL_BROWSER_OR_APP).build()
                    externalToken = null
                    billing.launchExternalLink(activity, params) { response ->
                        if (response.responseCode == BillingClient.BillingResponseCode.OK) result.success(true) else fail(result)
                    }
                }
            }
            "restore" -> connect("PLAY", result) { billing ->
                billing.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()) { response, purchases ->
                    if (response.responseCode == BillingClient.BillingResponseCode.OK) result.success(purchases.map(::purchase)) else fail(result)
                }
            }
            "manage" -> {
                // Google Play subscription management never switches providers or opens ClayDock checkout.
                activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/account/subscriptions?package=" + activity.packageName)))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
    fun close() { client?.endConnection(); client = null; pendingPurchase = null }
}
