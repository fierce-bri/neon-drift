extends Node
## Publishes a small JSON state snapshot to `window.__NEON_DRIFT__` in web
## builds so automated browser playtests can assert on game state.

const INTERVAL := 0.2

var _timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(OS.has_feature("web"))


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = INTERVAL
	var main := get_parent()
	if main and main.has_method("debug_state"):
		JavaScriptBridge.eval("window.__NEON_DRIFT__ = %s;" % JSON.stringify(main.debug_state()), true)
