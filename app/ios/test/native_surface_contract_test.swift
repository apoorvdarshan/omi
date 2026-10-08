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
        try graphContract()
        print("Native surface contract: typed values, command IDs, uniqueness and invalidation passed")
    }

    /// Knowledge-graph rows follow the same rules as native_graph.dart and IosNativeSurface.
    static func graphContract() throws {
        let base: [String: Any] = ["version": 1, "revision": 0, "title": "Memory Graph", "appearance": "dark",
            "locale": "en", "direction": "ltr", "loading": false, "failed": false, "empty": "", "toolbar": [],
            "searchEnabled": false, "searchValue": "", "searchPlaceholder": "", "refreshEnabled": false,
            "error": "Error", "retry": "Retry", "loadingLabel": "Loading"]
        func node(_ id: String, _ type: String = "concept", x: Double = 1, y: Double = 1, z: Double = 1,
                  fixed: Bool = false, label: String = "Node") -> [String: Any] {
            ["id": id, "label": label, "type": type, "x": x, "y": y, "z": z, "fixed": fixed]
        }
        func edge(_ source: String, _ target: String, _ label: String = "") -> [String: Any] {
            ["source": source, "target": target, "label": label]
        }
        let nodes = [node("me", "user", x: 0, y: 0, z: 0, fixed: true, label: "You"), node("ada", "person"),
                     node("paris", "place", x: 120, y: -120, z: 300)]
        let edges = [edge("me", "ada", "knows"), edge("ada", "paris")]
        let fill: [String: Any] = ["nodes": nodes, "edges": edges, "highlighted": [], "zoom": 1.0, "interactive": true,
                                   "layout": "fill", "placeholder": false, "accent": "#1A2B3C"]
        var card = fill
        card["layout"] = "card"; card["height"] = 140.0; card["interactive"] = false
        var placeholder = fill
        placeholder["nodes"] = []; placeholder["edges"] = []; placeholder["interactive"] = false; placeholder["placeholder"] = true
        func with(_ graph: [String: Any], _ key: String, _ value: Any) -> [String: Any] {
            var copy = graph
            copy[key] = value
            return copy
        }
        func row(_ id: String, _ kind: String) -> [String: Any] {
            ["id": id, "title": id, "kind": kind, "subtitle": "", "options": [], "destructive": false, "enabled": true]
        }
        func graphRow(_ graph: [String: Any]?, value: Any? = "", id: String = "graph", kind: String = "graph") -> [String: Any] {
            var result = row(id, kind)
            if let graph { result["graph"] = graph }
            if let value { result["value"] = value }
            return result
        }
        func surface(_ rows: [[String: Any]], _ change: (inout [String: Any]) -> Void = { _ in }) -> [String: Any] {
            var result = base
            result["sections"] = [["id": "graph", "title": "", "footer": "", "rows": rows]]
            change(&result)
            return result
        }
        func single(_ graph: [String: Any], value: Any? = "") -> [String: Any] { surface([graphRow(graph, value: value)]) }

        let stage = try NativeSurfaceSnapshot.decode(surface([row("hint", "label"), graphRow(fill), row("retry", "button")]) {
            var menu = row("share", "menu")
            menu["options"] = [["id": "png", "title": "Image"]]
            $0["toolbar"] = [menu]
        })
        precondition(stage.fillGraphRow?.id == "graph" && stage.fillGraphRow?.graph?.nodes.count == 3)
        precondition(stage.replacingValue(id: "graph", value: .text("ada")).sections[0].rows[1].graph == stage.fillGraphRow?.graph)
        precondition(stage.withoutContent().fillGraphRow == nil)
        var selected = with(fill, "highlighted", ["ada", "me"])
        _ = try NativeSurfaceSnapshot.decode(single(selected, value: "ada"))
        _ = try NativeSurfaceSnapshot.decode(single(card, value: nil))
        _ = try NativeSurfaceSnapshot.decode(single(with(card, "highlighted", ["ada"]), value: nil))
        _ = try NativeSurfaceSnapshot.decode(single(placeholder, value: nil))
        _ = try NativeSurfaceSnapshot.decode(single(with(with(placeholder, "layout", "card"), "height", 140.0), value: nil))
        let cards = try NativeSurfaceSnapshot.decode(surface([graphRow(card, value: nil), row("open", "navigation")]) {
            $0["searchEnabled"] = true; $0["refreshEnabled"] = true
        })
        precondition(cards.fillGraphRow == nil)

        // Counts, identities, labels, types and coordinates.
        rejects(single(with(fill, "nodes", []), value: ""))
        let many = (0..<1025).map { node("n\($0)") }
        _ = try NativeSurfaceSnapshot.decode(single(with(with(fill, "nodes", Array(many.prefix(1024))), "edges", [])))
        rejects(single(with(with(fill, "nodes", many), "edges", [])))
        let pairs = (0..<4097).map { edge("n\($0 % 64)", "n\(64 + $0 % 64)", "edge \($0)") }
        let hundreds = with(fill, "nodes", Array(many.prefix(200)))
        _ = try NativeSurfaceSnapshot.decode(single(with(hundreds, "edges", Array(pairs.prefix(4096)))))
        rejects(single(with(hundreds, "edges", pairs)))
        rejects(single(with(fill, "nodes", nodes + [node("ada")])))
        rejects(single(with(fill, "nodes", nodes + [node("")])))
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "nodes", nodes + [node(String(repeating: "x", count: 256))])))
        rejects(single(with(fill, "nodes", nodes + [node(String(repeating: "x", count: 257))])))
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "nodes", nodes + [node("long", label: String(repeating: "a", count: 256))])))
        rejects(single(with(fill, "nodes", nodes + [node("long", label: String(repeating: "a", count: 257))])))
        for type in ["user", "person", "place", "organization", "thing", "concept"] {
            _ = try NativeSurfaceSnapshot.decode(single(with(fill, "nodes", nodes + [node("typed", type)])))
        }
        rejects(single(with(fill, "nodes", nodes + [node("typed", "event")])))
        for value in [Double.nan, .infinity, 1e6 + 1, -1e6 - 1] {
            rejects(single(with(fill, "nodes", nodes + [node("bad", x: value)])))
            rejects(single(with(fill, "nodes", nodes + [node("bad", y: value)])))
            rejects(single(with(fill, "nodes", nodes + [node("bad", z: value)])))
        }
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "nodes", nodes + [node("far", x: 1e6, y: -1e6, z: 1e6)])))

        // One fixed node: the user, at the origin.
        rejects(single(with(fill, "nodes", nodes + [node("me2", "user", x: 0, y: 0, z: 0, fixed: true)])))
        rejects(single(with(with(fill, "nodes", [node("me", "person", x: 0, y: 0, z: 0, fixed: true)]), "edges", [])))
        rejects(single(with(with(fill, "nodes", [node("me", "user", x: 0, y: 1, z: 0, fixed: true)]), "edges", [])))

        // Edges.
        rejects(single(with(fill, "edges", edges + [edge("me", "ghost")])))
        rejects(single(with(fill, "edges", edges + [edge("ghost", "me")])))
        rejects(single(with(fill, "edges", edges + [edge("ada", "ada", "self")])))
        rejects(single(with(fill, "edges", edges + [edge("me", "ada", "knows")])))
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "edges", edges + [edge("me", "ada", "met"), edge("ada", "me", "knows")])))
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "edges", edges + [edge("paris", "me", String(repeating: "e", count: 128))])))
        rejects(single(with(fill, "edges", edges + [edge("paris", "me", String(repeating: "e", count: 129))])))

        // Highlights and the selected value.
        let six = (0..<6).map { node("h\($0)") }
        let highlighted = with(with(fill, "nodes", six), "edges", [])
        _ = try NativeSurfaceSnapshot.decode(single(with(highlighted, "highlighted", ["h0", "h1", "h2", "h3", "h4"]), value: "h0"))
        rejects(single(with(highlighted, "highlighted", ["h0", "h1", "h2", "h3", "h4", "h5"]), value: "h0"))
        rejects(single(with(fill, "highlighted", ["ada", "ghost"]), value: "ada"))
        rejects(single(with(fill, "highlighted", ["ada", "ada"]), value: "ada"))
        selected = with(fill, "highlighted", ["ada"])
        rejects(single(selected, value: ""))
        rejects(single(fill, value: "ghost"))
        rejects(single(fill, value: nil))
        rejects(single(fill, value: true))
        rejects(single(card, value: ""))
        rejects(single(placeholder, value: ""))

        // Zoom, layout, height and accent.
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "zoom", 0.05)))
        _ = try NativeSurfaceSnapshot.decode(single(with(fill, "zoom", 5.0)))
        rejects(single(with(fill, "zoom", 0.049)))
        rejects(single(with(fill, "zoom", 5.01)))
        _ = try NativeSurfaceSnapshot.decode(single(with(card, "height", 100.0), value: nil))
        _ = try NativeSurfaceSnapshot.decode(single(with(card, "height", 600.0), value: nil))
        rejects(single(with(card, "height", 99.0), value: nil))
        rejects(single(with(card, "height", 601.0), value: nil))
        var heightless = card
        heightless.removeValue(forKey: "height")
        rejects(single(heightless, value: nil))
        rejects(single(with(card, "interactive", true), value: ""))
        rejects(single(with(fill, "height", 300.0)))
        rejects(single(with(fill, "layout", "sheet")))
        for accent in ["#1a2b3c", "#ABCDEF"] { _ = try NativeSurfaceSnapshot.decode(single(with(fill, "accent", accent))) }
        for accent in ["1A2B3C", "#1A2B3", "#1A2B3CA", "#GGGGGG", "#1A2B3C\n", "＃１Ａ２Ｂ３Ｃ", ""] {
            rejects(single(with(fill, "accent", accent)))
        }

        // A placeholder is empty and sends nothing.
        rejects(single(with(placeholder, "nodes", nodes), value: nil))
        rejects(single(with(placeholder, "edges", [edge("me", "ada")]), value: nil))
        rejects(single(with(placeholder, "interactive", true), value: ""))
        rejects(single(with(with(placeholder, "layout", "card"), "height", 99.0), value: nil))

        // Kind and placement.
        rejects(surface([graphRow(nil)]))
        rejects(surface([graphRow(fill, value: nil, kind: "label")]))
        rejects(surface([graphRow(fill), graphRow(fill, id: "second")]))
        rejects(surface([graphRow(fill), graphRow(card, value: nil, id: "card")]))
        rejects(surface([graphRow(fill), row("open", "navigation")]))
        rejects(surface([graphRow(fill), graphRow(nil, value: true, kind: "toggle")]))
        rejects(surface([graphRow(fill)]) { $0["searchEnabled"] = true })
        rejects(surface([graphRow(fill)]) { $0["refreshEnabled"] = true })
        rejects(surface([graphRow(fill)]) {
            $0["chat"] = ["draft": "", "placeholder": "Ask", "followup": "", "streaming": false, "actions": []]
        })
        rejects(surface([graphRow(fill)]) { $0["reader"] = ["request": 0, "following": false, "footer": []] })
        rejects(surface([graphRow(fill)]) {
            $0["navigation"] = ["id": "main_destination", "title": "", "kind": "segmented", "subtitle": "", "value": "home",
                "enabled": true, "destructive": false,
                "options": ["home", "tasks", "memories", "apps", "settings"].map { ["id": $0, "title": $0] }]
        })
        rejects(surface([]) { $0["toolbar"] = [graphRow(card, value: nil)] })
    }
    static func rejects(_ input: Any) {
        do { _ = try NativeSurfaceSnapshot.decode(input) }
        catch { return }
        preconditionFailure("Invalid native form accepted")
    }
}
