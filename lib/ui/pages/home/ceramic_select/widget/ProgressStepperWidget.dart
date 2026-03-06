import 'package:flutter/material.dart';
import 'package:ceramic_app/objects/stage_dto.dart';

class ProgressStepperWidget extends StatelessWidget {
  final List<StageDto> stages;
  final StageDto currentStep;
  final ValueChanged<StageDto> onChanged;

  const ProgressStepperWidget({
    Key? key,
    required this.stages,
    required this.currentStep,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final done = stage.id <= currentStep.id;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(stage),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done ? Colors.green : Colors.grey,
                  child: done
                      ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.black,
                  )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  stage.title,
                  style: const TextStyle(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
