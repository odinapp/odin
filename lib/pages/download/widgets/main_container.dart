part of '../view.dart';

class MainContainer extends StatelessWidget {
  const MainContainer({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
      child: Container(
        width: 1040.toAutoScaledWidth,
        height: 688.toAutoScaledHeight,
        decoration: BoxDecoration(
          color: color.cardOnBackground,
          borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
        ),
        child: Stack(
          children: [
            _BackButton(color: color),
            MainContent(color: color),
          ],
        ),
      ),
    );
  }
}

class MainContent extends StatefulWidget {
  const MainContent({
    Key? key,
    required this.color,
  }) : super(key: key);

  final OColor color;

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  late final TextEditingController _tokenController;

  String token = '';
  ODebounce debounce = ODebounce(const Duration(milliseconds: 240));

  @override
  void initState() {
    _tokenController = TextEditingController();
    super.initState();
  }

  Future<void> _fetchMetadata() async {
    final dioNotifier = locator<DioNotifier>();

    await dioNotifier.fetchFilesMetadata(
      token,
      (count, total) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderText(color: widget.color),
            _ClickableInfoText(
              color: widget.color,
              onTap: () {},
              text: oApp.currentConfig?.token.description ??
                  'Ask your friend for this unique token to download the shared files. Without it you won’t be able to download the files. ',
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            60.toAutoScaledWidth.toHorizontalSizedBox,
            _buildTextField(context),
            60.toAutoScaledWidth.toHorizontalSizedBox,
            _PrimaryButton(
              color: widget.color,
              enabled: Provider.of<DioNotifier>(context).miniApiStatus == ApiStatus.success && token.length > 3,
              onPressed: _fetchMetadata,
            ),
            60.toAutoScaledWidth.toHorizontalSizedBox,
          ],
        ),
        _MetadataText(
          color: widget.color,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTextField(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
      child: Container(
        width: 560.toAutoScaledWidth,
        height: 96.toAutoScaledHeight,
        decoration: BoxDecoration(
          color: widget.color.secondaryContainerOnBackground,
          borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(
                  color: widget.color.secondaryOnBackground,
                  fontSize: 22.toAutoScaledFont,
                  fontWeight: FontWeight.w300,
                  height: 28.toAutoScaledFont / 22.toAutoScaledFont,
                ),
                controller: _tokenController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  hintText: oApp.currentConfig?.token.textFieldHintText ?? 'Enter 21 chars long unique token',
                  hintStyle: TextStyle(
                    color: widget.color.secondaryOnBackground,
                    fontSize: 22.toAutoScaledFont,
                    fontWeight: FontWeight.w300,
                    height: 28.toAutoScaledFont / 22.toAutoScaledFont,
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(21),
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9]'),
                  ),
                ],
                onChanged: (value) async {
                  setState(() {
                    token = value;
                  });
                  if (token.length > 3) {
                    debounce.call(_fetchMetadata);
                  } else {
                    Provider.of<DioNotifier>(context, listen: false).miniApiStatus = ApiStatus.init;
                  }
                },
              ),
            ),
            if (Provider.of<DioNotifier>(context).miniApiStatus == ApiStatus.loading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24.toAutoScaledWidth,
                  height: 24.toAutoScaledHeight,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.toAutoScaledWidth,
                  ),
                ),
              )
            else if (Provider.of<DioNotifier>(context).miniApiStatus == ApiStatus.failed)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 24.toAutoScaledWidth,
                ),
              )
            else if (Provider.of<DioNotifier>(context).miniApiStatus == ApiStatus.success)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.check,
                  color: widget.color.primary,
                  size: 24.toAutoScaledWidth,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    debounce.dispose();
  }
}
