import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/video_info.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import 'roi_setting_page.dart';

/// STEP 3 — 영상 정보(해상도/FPS) 입력.
/// (기존 Android: VideoSizeActivity — width/height/fps 입력 + 프리셋 버튼)
class VideoInfoPage extends StatefulWidget {
  const VideoInfoPage({super.key});

  static const String routeName = '/video-info';

  @override
  State<VideoInfoPage> createState() => _VideoInfoPageState();
}

class _VideoInfoPageState extends State<VideoInfoPage> {
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _fpsController = TextEditingController();

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _fpsController.dispose();
    super.dispose();
  }

  void _applyResolution(int width, int height) {
    _widthController.text = '$width';
    _heightController.text = '$height';
  }

  void _applyFps(int fps) => _fpsController.text = '$fps';

  void _confirm() {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    final fps = double.tryParse(_fpsController.text);

    if (width == null ||
        height == null ||
        fps == null ||
        width <= 0 ||
        height <= 0 ||
        fps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 값을 입력해주세요')),
      );
      return;
    }

    context.read<DiagnosisSession>().setVideoInfo(
          VideoInfo(width: width, height: height, fps: fps),
        );
    Navigator.pushNamed(context, RoiSettingPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영상 정보')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 3,
              total: 9,
              title: '영상 정보',
              description: '해상도(가로/세로)와 FPS 를 입력합니다.',
            ),
            Expanded(
              child: ListView(
                children: [
                  _field('가로 (width)', _widthController),
                  _field('세로 (height)', _heightController),
                  _field('FPS', _fpsController),
                  const SizedBox(height: 8),
                  const Text('해상도 프리셋'),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _applyResolution(1080, 1920),
                        child: const Text('1080p 세로'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyResolution(1920, 1080),
                        child: const Text('1080p 가로'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyResolution(720, 1280),
                        child: const Text('720p 세로'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyResolution(1280, 720),
                        child: const Text('720p 가로'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('FPS 프리셋'),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _applyFps(120),
                        child: const Text('120'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyFps(240),
                        child: const Text('240'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PrimaryButton(
              label: '다음',
              liftFromSystemNav: true,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
