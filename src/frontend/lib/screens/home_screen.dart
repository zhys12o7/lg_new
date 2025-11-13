import 'package:flutter/material.dart';
import 'package:frontend/services/media_service.dart';
import 'package:frontend/services/volume_service.dart';
import 'package:frontend/widgets/custom_video_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 30),
          child: Column(
            children: [
              const _TopStatusBar(),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Expanded(
                            flex: 7,
                            child: _HeroSpotlight(
                              videoUrl:
                                  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                            ),
                          ),
                          SizedBox(width: 32),
                          Expanded(
                            flex: 5,
                            child: _MemoBoardWithBadge(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    const _AppDock(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  const _TopStatusBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        _TimeAndWeather(),
        SizedBox(width: 36),
        Expanded(child: _SearchField()),
        SizedBox(width: 36),
        _ProfileSummary(),
      ],
    );
  }
}

class _TimeAndWeather extends StatelessWidget {
  const _TimeAndWeather();

  String _formatTime(DateTime time) {
    final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final String minute = time.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle timeStyle = Theme.of(context).textTheme.displaySmall ??
        const TextStyle(fontSize: 40, fontWeight: FontWeight.w700);

    return SizedBox(
      width: 240,
      child: StreamBuilder<DateTime>(
        stream: Stream<DateTime>.periodic(
          const Duration(seconds: 1),
          (_) => DateTime.now(),
        ),
        builder: (context, snapshot) {
          final DateTime now = snapshot.data ?? DateTime.now();
          final String period = now.hour >= 12 ? 'PM' : 'AM';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(now),
                    style: timeStyle.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF222328),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      period,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D606A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.wb_sunny_rounded, color: Color(0xFFF5A623)),
                  SizedBox(width: 6),
                  Text(
                    '17°C',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C3F47),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '무엇을 도와드릴까요?',
            hintStyle: const TextStyle(color: Color(0xFF9AA0AF)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9AA0AF)),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF9AA0AF)),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFD8DAE5),
            child: Icon(Icons.person_outline_rounded, color: Color(0xFF626678)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '홍길동',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF232533),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '다른 계정으로 전환하기',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7B7F8E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSpotlight extends StatefulWidget {
  const _HeroSpotlight({required this.videoUrl});

  final String videoUrl;

  @override
  State<_HeroSpotlight> createState() => _HeroSpotlightState();
}

class _HeroSpotlightState extends State<_HeroSpotlight> {
  int _volume = 15;
  bool _muted = false;
  bool _loading = false;
  bool _openingMedia = false;
  String? _mediaSessionId;

  final MediaService _mediaService = mediaService;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 34,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomVideoWidget(
                        videoUrl: widget.videoUrl,
                        autoplay: true,
                        looping: true,
                        volume: 0.0,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.black.withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 24,
                      right: 24,
                      child: _VolumeControllerBar(
                        volume: _volume,
                        muted: _muted,
                        loading: _loading,
                        onVolumeChange: _changeVolume,
                        onToggleMute: _toggleMute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THE GENTLEMEN',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF181A21),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'An American expat tries to sell off his highly profitable marijuana '
                              'empire in London, triggering plots, schemes, bribery and blackmail in '
                              'an attempt to steal his domain out from under him.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Color(0xFF4C505C),
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(
                                onPressed: _openingMedia ? null : _launchNativePlayback,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: _openingMedia
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('지금 보러가기'),
                              ),
                              const SizedBox(height: 22),
                              const Wrap(
                                spacing: 14,
                                runSpacing: 12,
                                children: [
                                  _TagChip(label: '액션'),
                                  _TagChip(label: '코미디'),
                                  _TagChip(label: '영국'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeVolume(bool increase) async {
    setState(() => _loading = true);
    final bool success = increase
        ? await volumeService.volumeUp()
        : await volumeService.volumeDown();
    if (!mounted) {
      return;
    }
    if (success) {
      setState(() {
        _muted = false;
        _volume = (increase ? _volume + 1 : _volume - 1).clamp(0, 100).toInt();
      });
    } else {
      _showMessage('볼륨을 변경하지 못했어요.');
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleMute() async {
    setState(() => _loading = true);
    final bool success = await volumeService.setMuted(!_muted);
    if (!mounted) {
      return;
    }
    if (success) {
      setState(() => _muted = !_muted);
    } else {
      _showMessage('음소거 상태를 변경하지 못했어요.');
    }
    setState(() => _loading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _launchNativePlayback() async {
    if (_openingMedia) {
      return;
    }
    setState(() => _openingMedia = true);
    try {
      final sessionId = await _mediaService.open(widget.videoUrl);
      if (!mounted) {
        return;
      }
      if (sessionId == null) {
        _showMessage('영상 재생을 시작하지 못했어요.');
      } else {
        _mediaSessionId = sessionId;
        await _mediaService.play(sessionId);
        if (mounted) {
          _showMessage('TV에서 영상 재생을 시작했어요.');
        }
      }
    } catch (error) {
      debugPrint('[media] open/play error: $error');
      if (mounted) {
        _showMessage('영상 재생 중 오류가 발생했어요.');
      }
    } finally {
      if (mounted) {
        setState(() => _openingMedia = false);
      }
    }
  }

  @override
  void dispose() {
    if (_mediaSessionId != null) {
      _mediaService.close(_mediaSessionId!);
      _mediaSessionId = null;
    }
    super.dispose();
  }
}

class _VolumeControllerBar extends StatelessWidget {
  const _VolumeControllerBar({
    required this.volume,
    required this.muted,
    required this.loading,
    required this.onVolumeChange,
    required this.onToggleMute,
  });

  final int volume;
  final bool muted;
  final bool loading;
  final Future<void> Function(bool increase) onVolumeChange;
  final Future<void> Function() onToggleMute;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleButton(
              icon: Icons.remove_rounded,
              onTap: loading ? null : () => onVolumeChange(false),
            ),
            const SizedBox(width: 12),
            _circleButton(
              icon: muted ? Icons.volume_off_rounded : Icons.volume_mute_rounded,
              onTap: loading ? null : onToggleMute,
            ),
            const SizedBox(width: 12),
            _circleButton(
              icon: Icons.add_rounded,
              onTap: loading ? null : () => onVolumeChange(true),
            ),
            const SizedBox(width: 18),
            Text(
              muted ? '음소거됨' : '볼륨 $volume',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(onTap == null ? 0.25 : 0.4),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _MemoBoardWithBadge extends StatelessWidget {
  const _MemoBoardWithBadge();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: const [
        _MemoBoard(),
        Positioned(
          top: 46,
          right: -30,
          child: _VerticalBadge(label: '빈버드'),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5F6372),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MemoBoard extends StatelessWidget {
  const _MemoBoard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 28,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Text(
                '메모하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1F25),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.edit_note_rounded, color: Color(0xFF9AA0AF)),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _MemoSticky(
                    title: '할일 메모',
                    content: '할일 정기 어쩌구',
                    color: Color(0xFF6DE4A5),
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: _MemoSticky(
                    title: '아이디어',
                    content: '',
                    color: Color(0xFFFFE28B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoSticky extends StatelessWidget {
  const _MemoSticky({
    required this.title,
    required this.content,
    required this.color,
  });

  final String title;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF272B33),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF3B3F46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalBadge extends StatelessWidget {
  const _VerticalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF4C1E1E),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(12, 18),
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDock extends StatelessWidget {
  const _AppDock();

  static final List<_DockItem> _items = [
    _DockItem(icon: Icons.movie_outlined, label: 'Disney+', color: const Color(0xFF0E7FE1)),
    _DockItem(icon: Icons.movie_outlined, label: 'Disney+', color: const Color(0xFF0E7FE1)),
    _DockItem(icon: Icons.ondemand_video_rounded, label: 'Netflix', color: Colors.red),
    _DockItem(icon: Icons.movie_outlined, label: 'Disney+', color: const Color(0xFF0E7FE1)),
    _DockItem(icon: Icons.video_library_rounded, label: 'YouTube', color: Colors.redAccent),
    _DockItem(icon: Icons.play_circle_fill_rounded, label: 'Play', color: const Color(0xFF6F9CFF)),
    _DockItem(icon: Icons.web_rounded, label: 'Wavve', color: const Color(0xFFBF3EFF)),
    _DockItem(icon: Icons.grid_view_rounded, label: 'Apps', color: const Color(0xFF4A90E2)),
    _DockItem(icon: Icons.photo_rounded, label: 'Gallery', color: const Color(0xFFFF6F91)),
    _DockItem(icon: Icons.photo_rounded, label: 'Gallery', color: const Color(0xFFFF6F91)),
    _DockItem(icon: Icons.add_rounded, label: '추가', color: const Color(0xFFE0E3EC)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final _DockItem item in _items) _DockIcon(item: item),
        ],
      ),
    );
  }
}

class _DockItem {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.item});

  final _DockItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withOpacity(0.18),
                item.color.withOpacity(0.32),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(item.icon, size: 32, color: item.color),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6E7281),
          ),
        ),
      ],
    );
  }
}

