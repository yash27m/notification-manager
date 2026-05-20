import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_manager/screens/home/dashboard/dashboard_widgets.dart';

class FontStyleData {
  final String title;
  final String upper;
  final String lower;
  bool isCopied;

  FontStyleData({
    required this.title,
    required this.upper,
    required this.lower,
    this.isCopied = false,
  });
}

class FontStyleGenerator extends StatefulWidget {
  const FontStyleGenerator({super.key});

  @override
  State<FontStyleGenerator> createState() => _FontStyleGeneratorState();
}

class _FontStyleGeneratorState extends State<FontStyleGenerator> {
  final TextEditingController _controller = TextEditingController();
  String _inputText = "Hello";

  // Data structure holding your specific Unicode strings
  final List<FontStyleData> _fontStyles = [
    FontStyleData(
      title: "Fraktur / Gothic",
      lower: "𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷",
      upper: "𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ",
    ),
    FontStyleData(
      title: "Bold Fraktur",
      lower: "𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟",
      upper: "𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅",
    ),
    FontStyleData(
      title: "Bold Script",
      lower: "𝓪𝓫𝓬𝓭𝓮𝓯𝓰𝓱𝓲𝓳𝓴𝓵𝓶𝓷𝓸𝓹𝓺𝓻𝓼𝓽𝓾𝓿𝔀𝔁𝔂𝔃",
      upper: "𝓐𝓑𝓒𝓓𝓔𝓕𝓖𝓗𝓘𝓙𝓚𝓛𝓜𝓝𝓞𝓟𝓠𝓡𝓢𝓣𝓤𝓥𝓦𝓧𝓨𝓩",
    ),
    FontStyleData(
      title: "Light Script",
      lower: "𝒶𝒷𝒸𝒹𝑒𝒻𝑔𝒽𝒾𝒿𝓀𝓁𝓂𝓃𝑜𝓅𝓆𝓇𝓈𝓉𝓊𝓋𝓌𝓍𝓎𝓏",
      upper: "𝒜𝐵𝒞𝒟𝐸𝐹𝒢𝐻𝐼𝒥𝒦𝐿𝑀𝒩𝒪𝒫𝒬𝑅𝒮𝒯𝒰𝒱𝒲𝒳𝒴𝒵",
    ),
    FontStyleData(
      title: "Double Struck",
      lower: "𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫",
      upper: "𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ",
    ),
    FontStyleData(
      title: "Full Width",
      lower: "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ",
      upper: "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ",
    ),
    FontStyleData(
      title: "Small Caps",
      lower: "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀꜱᴛᴜᴠᴡxʏᴢ",
      upper: "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀꜱᴛᴜᴠᴡxʏᴢ",
    ),
    FontStyleData(
      title: "Squared / Negative",
      lower: "🅰🅱🅲🅳🅴🅵🅶🅷🅸𝓳🅺🅻🅼🅽🅾🅿🆀🆁🆂🆃🆄🆅🆆🆇🆈🆉",
      upper: "🅰🅱🅲🅳🅴🅵🅶🅷🅸🅹🅺🅻🅼🅽🅾🅿🆀🆁🆂🆃🆄🆅🆆🆇🆈🆉",
    ),
    FontStyleData(
      title: "Circled",
      lower: "ⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ",
      upper: "ⒶⒷⒸⒹⒺⒻⒼⒽⒾⒿⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏ",
    ),
    FontStyleData(
      title: "Bold Sans",
      lower: "𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝗅𝘆𝘇",
      upper: "𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭",
    ),
    FontStyleData(
      title: "Monospace",
      lower: "𝚊𝚋𝚌𝚍𝚎𝚏𝚐𝚑𝚒𝚓𝚔𝚕𝚖𝚗𝚘𝚙𝚚𝚛𝚜𝚝𝚞𝚟𝚠𝚡𝚢𝚣",
      upper: "𝙰𝙱𝙲𝙳𝙴𝙵𝙶𝙷𝙸𝙹𝙺𝙻𝙼𝙽𝙾𝙿𝚀𝚁𝚂𝚃𝚄𝚅𝚆𝚇𝚈𝚉",
    ),
  ];

  // The Conversion Logic
  String _stylizeText(String text, FontStyleData style) {
    if (text.isEmpty) return "";

    const String plainUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const String plainLower = "abcdefghijklmnopqrstuvwxyz";

    // We use .characters to handle multi-byte Unicode properly
    List<String> upperChars = style.upper.characters.toList();
    List<String> lowerChars = style.lower.characters.toList();

    StringBuffer buffer = StringBuffer();

    for (var char in text.characters) {
      if (plainUpper.contains(char)) {
        int index = plainUpper.indexOf(char);
        buffer.write(index < upperChars.length ? upperChars[index] : char);
      } else if (plainLower.contains(char)) {
        int index = plainLower.indexOf(char);
        buffer.write(index < lowerChars.length ? lowerChars[index] : char);
      } else {
        buffer.write(char); // Return spaces/numbers as is
      }
    }
    return buffer.toString();
  }

  void _copyToClipboard(String text, int index) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _fontStyles[index].isCopied = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _fontStyles[index].isCopied = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Style copied to clipboard!"),
        backgroundColor: primary,
        duration: Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),

      body: Column(
        children: [
          // Input area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onChanged: (val) => setState(() => _inputText = val),
              decoration: InputDecoration(
                hintText: "Type your text here...",
                prefixIcon: const Icon(Icons.edit_note),
                filled: true,
                fillColor: accent.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _fontStyles.length,
              itemBuilder: (context, index) {
                final style = _fontStyles[index];
                final result = _stylizeText(_inputText, style);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      style.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        result.isEmpty ? "Preview Text" : result,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        style.isCopied
                            ? Icons.check_circle
                            : Icons.copy_rounded,
                      ),
                      color: style.isCopied ? primary : Colors.grey.shade400,
                      onPressed: () => _copyToClipboard(result, index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
