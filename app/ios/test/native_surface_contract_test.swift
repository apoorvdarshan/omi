import Foundation

@main
struct NativeSurfaceTests {
    static func main() throws {
        let row: [String: Any] = ["id": "appearance", "title": "Appearance", "kind": "choice", "subtitle": "",
            "value": "system", "options": [["id": "system", "title": "System"]], "destructive": false, "enabled": true]
        var input: [String: Any] = ["version": 1, "revision": 0, "title": "Settings", "appearance": "system",
            "locale": "en", "direction": "ltr", "loading": false, "failed": false, "empty": "",
            "sections": [["id": "settings", "title": "", "footer": "", "rows": [row]]], "toolbar": [],
            "searchEnabled": true, "searchValue": "private search", "searchPlaceholder": "Search", "refreshEnabled": false,
            "error": "Error", "retry": "Retry", "loadingLabel": "Loading"]
        let snapshot = try NativeSurfaceSnapshot.decode(input)
        var tabs = input
        tabs["sections"] = []
        tabs["searchEnabled"] = false
        var destinations: [String: Any] = ["id": "main_destination", "title": "", "kind": "segmented", "subtitle": "",
            "value": "home", "enabled": true, "destructive": false,
            "options": ["home", "tasks", "memories", "apps", "settings"].map { ["id": $0, "title": $0.capitalized] }]
        tabs["navigation"] = destinations
        let bar = try NativeSurfaceSnapshot.decode(tabs)
        precondition(bar.replacingValue(id: "main_destination", value: .text("settings")).navigation?.value?.text == "settings")
        precondition(bar.withoutContent().navigation == nil && bar.withoutContent().allRows.isEmpty)
        destinations["value"] = "arbitrary_route"
        tabs["navigation"] = destinations
        rejects(tabs)
        destinations["value"] = "home"
        destinations["options"] = [["id": "home", "title": "Home"]]
        tabs["navigation"] = destinations
        rejects(tabs)
        var keypad: [String: Any] = ["id": "keys", "title": "Keypad", "kind": "keypad", "subtitle": "",
            "value": "123", "keypadMode": "dtmf", "options": "0123456789*#".map { ["id": String($0), "title": ""] },
            "destructive": false, "enabled": true]
        var dialer = input
        dialer["sections"] = [["id": "keys", "title": "", "footer": "", "rows": [keypad]]]
        let keys = try NativeSurfaceSnapshot.decode(dialer)
        precondition(keys.replacingValue(id: "keys", value: .text("1234")).sections[0].rows[0].keypadMode == "dtmf")
        keypad["keypadMode"] = "dialer"
        dialer["sections"] = [["id": "keys", "title": "", "footer": "", "rows": [keypad]]]
        rejects(dialer)
        keypad["eraseLabel"] = "Delete"
        keypad["clearLabel"] = "Clear All"
        dialer["sections"] = [["id": "keys", "title": "", "footer": "", "rows": [keypad]]]
        _ = try NativeSurfaceSnapshot.decode(dialer)
        keypad["options"] = [["id": "1", "title": ""]]
        dialer["sections"] = [["id": "keys", "title": "", "footer": "", "rows": [keypad]]]
        rejects(dialer)
        var literal = row
        literal["kind"] = "message_ai"
        literal.removeValue(forKey: "value")
        literal["plainText"] = true
        dialer["sections"] = [["id": "literal", "title": "", "footer": "", "rows": [literal]]]
        _ = try NativeSurfaceSnapshot.decode(dialer)
        literal["kind"] = "button"
        dialer["sections"] = [["id": "literal", "title": "", "footer": "", "rows": [literal]]]
        rejects(dialer)
        precondition(snapshot.sections[0].rows[0].value?.text == "system")
        precondition(snapshot.largeTitle == nil)
        var searchable = row
        searchable["optionSearch"] = "Search countries"
        searchable["optionClose"] = "Close"
        var countries = input
        countries["sections"] = [["id": "country", "title": "", "footer": "", "rows": [searchable]]]
        let country = try NativeSurfaceSnapshot.decode(countries)
        precondition(country.replacingValue(id: "appearance", value: .text("system")).sections[0].rows[0].optionSearch == "Search countries")
        searchable.removeValue(forKey: "optionClose")
        countries["sections"] = [["id": "country", "title": "", "footer": "", "rows": [searchable]]]
        rejects(countries)
        var color = row
        color["kind"] = "color"
        color["value"] = "#3B82F6"
        color["options"] = [["id": "#3B82F6", "title": "Color 1"]]
        var palette = input
        palette["sections"] = [["id": "palette", "title": "", "footer": "", "rows": [color]]]
        _ = try NativeSurfaceSnapshot.decode(palette)
        color["options"] = [["id": "invalid", "title": "Color"]]
        palette["sections"] = [["id": "palette", "title": "", "footer": "", "rows": [color]]]
        rejects(palette)
        var meter = row
        meter["level"] = 4
        palette["sections"] = [["id": "meter", "title": "", "footer": "", "rows": [meter]]]
        rejects(palette)
        meter["level"] = 2
        meter["visibilityEnabled"] = true
        palette["sections"] = [["id": "meter", "title": "", "footer": "", "rows": [meter]]]
        let levels = try NativeSurfaceSnapshot.decode(palette)
        let revised = levels.replacingValue(id: "appearance", value: .text("system"))
        precondition(revised.revision == 1 && revised.sections[0].rows[0].level == 2)
        precondition(revised.sections[0].rows[0].visibilityEnabled == true)
        var navigation = row
        navigation["kind"] = "navigation"
        navigation.removeValue(forKey: "value")
        var settings = input
        settings["largeTitle"] = true
        settings["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [navigation]]]
        let nativeSettings = try NativeSurfaceSnapshot.decode(settings)
        precondition(nativeSettings.largeTitle == true)
        navigation["value"] = "arbitrary mutation"
        settings["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [navigation]]]
        rejects(settings)
        var playback = input
        let line: [String: Any] = ["id": "segment:1", "title": "Words", "kind": "transcript", "subtitle": "Speaker 1", "options": [], "enabled": true, "destructive": false]
        var slider: [String: Any] = ["id": "position", "title": "Audio", "kind": "slider", "subtitle": "", "value": 25.5, "maximumValue": 100, "options": [], "enabled": true, "destructive": false]
        playback["sections"] = [["id": "transcript", "title": "", "footer": "", "rows": [line]]]
        playback["reader"] = ["currentId": "segment:1", "targetId": "segment:1", "request": 1, "following": true, "footer": [slider]]
        let reader = try NativeSurfaceSnapshot.decode(playback)
        precondition(reader.reader?.footer.first?.value?.number == 25.5)
        precondition(reader.replacingValue(id: "position", value: .number(40)).reader?.footer.first?.value?.number == 40)
        precondition(reader.withoutContent().reader == nil)
        for value in [-1.0, 101.0] {
            slider["value"] = value
            playback["reader"] = ["request": 0, "following": false, "footer": [slider]]
            rejects(playback)
        }
        playback["reader"] = ["targetId": "foreign", "request": 0, "following": false, "footer": []]
        rejects(playback)
        var date = row; date["kind"] = "date"; date["value"] = true
        playback.removeValue(forKey: "reader")
        playback["sections"] = [["id": "date", "title": "", "footer": "", "rows": [date]]]
        rejects(playback)
        date["value"] = 10
        playback["sections"] = [["id": "date", "title": "", "footer": "", "rows": [date]]]
        rejects(playback)
        let cleared = snapshot.withoutContent()
        precondition(cleared.sections.isEmpty && cleared.toolbar.isEmpty && cleared.searchValue.isEmpty && cleared.title.isEmpty)
        var invalid = row
        for value: Any in [true, "missing"] {
            invalid["value"] = value
            input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [invalid]]]
            rejects(input)
        }
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [row, row]]]
        rejects(input)
        invalid = row
        invalid["id"] = "_refresh"
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [invalid]]]
        rejects(input)
        invalid = row
        invalid["kind"] = "date"
        invalid["value"] = "nan"
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [invalid]]]
        rejects(input)
        invalid["kind"] = "chart"
        invalid.removeValue(forKey: "value")
        invalid["points"] = [["x": 1, "y": 50, "label": "50%"], ["x": 1, "y": 60, "label": "60%"]]
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [invalid]]]
        rejects(input)
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [row]]]
        input["chat"] = ["draft": "private message", "placeholder": "Ask Omi", "followup": "", "streaming": false, "actions": []]
        let chatSnapshot = try NativeSurfaceSnapshot.decode(input)
        precondition(chatSnapshot.withoutContent().chat == nil)
        var text = row
        text["kind"] = "text"
        text["keyboard"] = "phone"
        text["value"] = ""
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [text]]]
        let phone = try NativeSurfaceSnapshot.decode(input)
        precondition(phone.sections[0].rows[0].keyboard == "phone")
        text["keyboard"] = "unknown"
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [text]]]
        rejects(input)
        text.removeValue(forKey: "keyboard")
        text["maximumLength"] = 2
        text["value"] = "👨‍👩‍👧‍👦a"
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [text]]]
        _ = try NativeSurfaceSnapshot.decode(input)
        text["value"] = "👨‍👩‍👧‍👦ab"
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [text]]]
        rejects(input)
        text["value"] = ""
        text["maximumLength"] = 0
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [text]]]
        rejects(input)
        var image = row
        for uri in ["https://example.com/a.jpg", "file:///sandbox/a.jpg"] {
            image["imageUri"] = uri
            input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [image]]]
            _ = try NativeSurfaceSnapshot.decode(input)
        }
        for uri in ["http://example.com/a", "file://other-host/a", "https://user:password@example.com/a", "javascript:alert(1)"] {
            image["imageUri"] = uri
            input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [image]]]
            rejects(input)
        }
        var wave = row
        wave["kind"] = "waveform"
        wave.removeValue(forKey: "value")
        wave["points"] = [["x": 0, "y": 0.5, "label": ""]]
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [wave]]]
        _ = try NativeSurfaceSnapshot.decode(input)
        wave["points"] = [["x": 0, "y": 2, "label": ""]]
        input["sections"] = [["id": "settings", "title": "", "footer": "", "rows": [wave]]]
        rejects(input)
        // 'level' mirrors NativeRow.valid/accepts in Dart: ordered finite bounds and a value on the step grid.
        var labelled = input
        labelled.removeValue(forKey: "chat")
        let brightness: [String: Any] = ["id": "led_brightness", "title": "LED Brightness", "kind": "level",
            "subtitle": "50%", "value": 50, "maximumValue": 100, "step": 25, "options": [], "enabled": true,
            "destructive": false]
        func levelSurface(_ changes: [String: Any?], kind: String = "level") -> [String: Any] {
            var row = brightness
            row["kind"] = kind
            for (key, value) in changes { row[key] = value }
            var surface = labelled
            surface["sections"] = [["id": "device", "title": "", "footer": "", "rows": [row]]]
            return surface
        }
        let levelControl = try NativeSurfaceSnapshot.decode(levelSurface([:])).sections[0].rows[0]
        precondition(levelControl.minimumValue == nil && levelControl.step == 25 && levelControl.value?.number == 50)
        let moved = levelControl.replacingValue(.number(75))
        precondition(moved.value?.number == 75 && moved.step == 25 && moved.maximumValue == 100 && moved.hasValidValue)
        precondition(!levelControl.replacingValue(.number(60)).hasValidValue)
        let validLevels: [[String: Any?]] = [
            ["value": 0], ["value": 100.0], ["step": nil, "value": 37.5],
            ["minimumValue": -10, "maximumValue": 10, "step": 0.5, "value": -2.5],
            ["minimumValue": 1, "maximumValue": 5, "step": 1, "value": 3],
            ["minimumValue": 0, "maximumValue": 1, "step": 0.1, "value": 0.30000000000000004],
            ["maximumValue": 10, "step": 4, "value": 8], ["maximumValue": 1000, "step": 1, "value": 999],
        ]
        for changes in validLevels { _ = try NativeSurfaceSnapshot.decode(levelSurface(changes)) }
        let invalidLevels: [[String: Any?]] = [
            ["maximumValue": nil], ["minimumValue": 100, "maximumValue": 100, "value": 100],
            ["minimumValue": 10, "maximumValue": 5, "step": nil, "value": 7],
            ["maximumValue": Double.nan], ["maximumValue": Double.infinity], ["minimumValue": Double.nan],
            ["minimumValue": -Double.infinity], ["value": Double.nan], ["step": nil, "value": Double.infinity],
            ["value": nil], ["value": "50"], ["value": true], ["value": 60],
            ["minimumValue": 1, "maximumValue": 5, "step": 2, "value": 2],
            ["minimumValue": 10, "step": nil, "value": 5], ["value": 125], ["value": -25],
            ["step": 0], ["step": -25], ["step": Double.nan], ["step": Double.infinity], ["step": 101, "value": 0],
            ["maximumValue": 1001, "step": 1, "value": 1],
        ]
        for changes in invalidLevels { rejects(levelSurface(changes)) }
        // Bounds and steps belong to the level control only; the playback slider keeps its contract.
        rejects(levelSurface([:], kind: "slider"))
        rejects(levelSurface(["step": nil, "minimumValue": 0], kind: "slider"))
        rejects(levelSurface([:], kind: "progress"))
        rejects(levelSurface(["value": nil, "maximumValue": nil], kind: "button"))
        rejects(levelSurface(["value": nil, "maximumValue": nil, "step": nil, "minimumValue": 0], kind: "button"))
        _ = try NativeSurfaceSnapshot.decode(levelSurface(["step": nil, "value": 25.5], kind: "slider"))
        for number in [0.0, 25, 50, 75.00000001, 100] { precondition(levelControl.acceptsLevel(number)) }
        for number in [-25.0, 125, 60, 12.5, .nan, .infinity, -Double.infinity] { precondition(!levelControl.acceptsLevel(number)) }
        let free = try NativeSurfaceSnapshot.decode(levelSurface(["minimumValue": -1, "maximumValue": 1, "step": nil, "value": 0]))
        precondition(free.sections[0].rows[0].acceptsLevel(-0.333) && !free.sections[0].rows[0].acceptsLevel(1.0001))
        print("Native surface contract: typed values, command IDs, uniqueness and invalidation passed")
    }
    static func rejects(_ input: Any) {
        do { _ = try NativeSurfaceSnapshot.decode(input) }
        catch { return }
        preconditionFailure("Invalid native form accepted")
    }
}
