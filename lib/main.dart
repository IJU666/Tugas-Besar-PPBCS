import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1ED760),
          secondary: Color(0xFF7C5CFF),
          surface: Color(0xFF15151B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class Song {
  final String title;
  final String artist;
  final String url;
  final List<Color> gradient;
  const Song({
    required this.title,
    required this.artist,
    required this.url,
    required this.gradient,
  });
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

enum _PlaybackState { idle, loading, playing, paused, error }

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;

  final List<Song> songs = const [
    Song(
      title: 'Song 1',
      artist: 'Unknown Artist',
      url: 'https://gitlab.com/davafath12/test/-/raw/main/song1.mp3',
      gradient: [Color(0xFFFF5A36), Color(0xFFB3271F)],
    ),
    Song(
      title: 'Song 2',
      artist: 'Unknown Artist',
      url: 'https://gitlab.com/davafath12/test/-/raw/main/song2.mp3',
      gradient: [Color(0xFF2DD4BF), Color(0xFF1565C0)],
    ),
    Song(
      title: 'Song 3',
      artist: 'Unknown Artist',
      url: 'https://gitlab.com/davafath12/test/-/raw/main/song3.mp3',
      gradient: [Color(0xFF7C5CFF), Color(0xFFD6418E)],
    ),
  ];

  int? _currentIndex;
  _PlaybackState _state = _PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  late AnimationController _spinController;

  Song? get _currentSong =>
      _currentIndex == null ? null : songs[_currentIndex!];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() {
        if (s == PlayerState.playing) {
          _state = _PlaybackState.playing;
        } else if (s == PlayerState.paused) {
          _state = _PlaybackState.paused;
        } else if (s == PlayerState.stopped) {
          _state = _PlaybackState.idle;
        }
      });
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      _playNext();
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _spinController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSongAt(int index) async {
    final song = songs[index];
    setState(() {
      _currentIndex = index;
      _state = _PlaybackState.loading;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(song.url));
      if (!mounted) return;
      setState(() => _state = _PlaybackState.playing);
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _PlaybackState.error);
    }
  }

  void _togglePlayPause() {
    if (_currentIndex == null) return;
    if (_state == _PlaybackState.playing) {
      _audioPlayer.pause();
    } else if (_state == _PlaybackState.paused) {
      _audioPlayer.resume();
    } else if (_state == _PlaybackState.error) {
      _playSongAt(_currentIndex!);
    }
  }

  void _playNext() {
    if (_currentIndex == null) return;
    final next = (_currentIndex! + 1) % songs.length;
    _playSongAt(next);
  }

  void _playPrevious() {
    if (_currentIndex == null) return;
    final prev = (_currentIndex! - 1 + songs.length) % songs.length;
    _playSongAt(prev);
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSong = _currentIndex != null;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF0B0B0F),
                  elevation: 0,
                  pinned: true,
                  titleSpacing: 20,
                  title: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1ED760),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AUDIO PLAYER',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Koleksi Lagu',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} lagu dari internet',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8A8A93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    hasActiveSong ? 110 : 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildSongTile(index),
                      childCount: songs.length,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (hasActiveSong)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(top: false, child: _buildMiniPlayer()),
            ),
        ],
      ),
    );
  }

  Widget _buildSongTile(int index) {
    final song = songs[index];
    final isActive = _currentIndex == index;
    final isPlaying = isActive && _state == _PlaybackState.playing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _playSongAt(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1C1C24) : const Color(0xFF15151B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF1ED760)
                  : const Color(0xFF22222B),
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: song.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.music_note_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isActive
                            ? const Color(0xFF1ED760)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF8A8A93),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1ED760)
                      : const Color(0xFF22222B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive && _state == _PlaybackState.loading
                      ? Icons.hourglass_top_rounded
                      : (isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                  color: isActive ? Colors.black : Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final song = _currentSong!;
    final isPlaying = _state == _PlaybackState.playing;
    final isLoading = _state == _PlaybackState.loading;
    final isError = _state == _PlaybackState.error;

    final maxMs = _duration.inMilliseconds.clamp(1, double.maxFinite.toInt());
    final posMs = _position.inMilliseconds.clamp(0, maxMs).toDouble();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26262F)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: const Color(0xFF1ED760),
                inactiveTrackColor: const Color(0xFF2A2A33),
                thumbColor: const Color(0xFF1ED760),
              ),
              child: SizedBox(
                height: 14,
                child: Slider(
                  min: 0,
                  max: maxMs.toDouble(),
                  value: posMs,
                  onChanged: isError
                      ? null
                      : (v) => _audioPlayer.seek(
                          Duration(milliseconds: v.round()),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(
                      color: Color(0xFF8A8A93),
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: Color(0xFF8A8A93),
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: isPlaying ? _spinController.value * 6.28319 : 0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: song.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isError
                            ? 'Gagal memutar lagu'
                            : (isLoading ? 'Memuat…' : song.artist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isError
                              ? const Color(0xFFFF5A36)
                              : const Color(0xFF8A8A93),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _miniIconButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: _playPrevious,
                ),
                const SizedBox(width: 4),
                _miniIconButton(
                  icon: isLoading
                      ? Icons.hourglass_top_rounded
                      : (isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded),
                  onTap: _togglePlayPause,
                  primary: true,
                ),
                const SizedBox(width: 4),
                _miniIconButton(
                  icon: Icons.skip_next_rounded,
                  onTap: _playNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          color: primary ? const Color(0xFF1ED760) : Colors.white,
          size: primary ? 38 : 26,
        ),
      ),
    );
  }
}
