import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:foxxy_package/generated/l10n.dart';

final Map<String, String> availableLanguages = {
  'Chinese': 'zh',
  'English': 'en',
};

getLanguageName(String code) {
  return availableLanguages.entries
      .firstWhere((element) => element.value == code)
      .key;
}

getRecordingSettings(
    Function(String?) onLanguageChanged, String selectedLanguage) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        S.current.SpeechLanguage,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      Container(
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButton<String>(
          value: selectedLanguage,
          onChanged: onLanguageChanged,
          dropdownColor: Colors.grey.shade900,
          style: TextStyle(color: Colors.white, fontSize: 14),
          underline: SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
          items: availableLanguages.keys
              .map<DropdownMenuItem<String>>((String key) {
            return DropdownMenuItem<String>(
              value: availableLanguages[key],
              child: Text(
                key,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class LanguageSettingWidget extends StatefulWidget {
  const LanguageSettingWidget({Key? key}) : super(key: key);

  @override
  _LanguageSettingWidgetState createState() => _LanguageSettingWidgetState();
}

class _LanguageSettingWidgetState extends State<LanguageSettingWidget> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = SharedPreferencesUtil().recordingsLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return getRecordingSettings(
      (String? newValue) {
        if (newValue == null || newValue == _selectedLanguage) return;
        setState(() => _selectedLanguage = newValue);
        SharedPreferencesUtil().recordingsLanguage = _selectedLanguage;
        // TODO(yiqi): should do reconnections when language changes.
        MixpanelManager().recordingLanguageChanged(_selectedLanguage);
      },
      _selectedLanguage,
    );
  }
}
