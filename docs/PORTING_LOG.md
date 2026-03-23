# FNF-PsychEngine(원본 1.0.4 버전) vs FNF-PsychEngine-1.0.4(수정됨) 소스 비교

**비교 대상**
- A: `FNF-PsychEngine/source/`
- B: `FNF-PsychEngine-1.0.4/source/`

총 157개 파일 중 **10개 파일** 변경, 추가/삭제된 파일 없음

---

## 1. `backend/ClientPrefs.hx`

`data.*` 필드에 대한 static getter/setter 프로퍼티 추가 (구버전 스크립트 호환용)

```haxe
// 추가됨
public static var camZooms(get, set):Bool;
static function get_camZooms():Bool return data.camZooms;
static function set_camZooms(v:Bool):Bool return data.camZooms = v;

public static var shaders(get, set):Bool;
static function get_shaders():Bool return data.shaders;
static function set_shaders(v:Bool):Bool return data.shaders = v;

public static var lowQuality(get, set):Bool;
static function get_lowQuality():Bool return data.lowQuality;
static function set_lowQuality(v:Bool):Bool return data.lowQuality = v;

public static var antialiasing(get, set):Bool;
static function get_antialiasing():Bool return data.antialiasing;
static function set_antialiasing(v:Bool):Bool return data.antialiasing = v;

public static var framerate(get, set):Int;
static function get_framerate():Int return data.framerate;
static function set_framerate(v:Int):Int return data.framerate = v;

public static var healthBarAlpha(get, set):Float;
static function get_healthBarAlpha():Float return data.healthBarAlpha;
static function set_healthBarAlpha(v:Float):Float return data.healthBarAlpha = v;

public static var downScroll(get, set):Bool;
static function get_downScroll():Bool return data.downScroll;
static function set_downScroll(v:Bool):Bool return data.downScroll = v;
```

---

## 2. `backend/Song.hx`

구버전(0.6.3) 차트의 `arrowSkin`/`splashSkin` 경로 자동 보정 추가

```haxe
// 추가됨
if(songJson.arrowSkin != null && songJson.arrowSkin.indexOf('/') < 0)
    songJson.arrowSkin = 'noteSkins/' + songJson.arrowSkin;
if(songJson.splashSkin != null && songJson.splashSkin.indexOf('/') < 0)
    songJson.splashSkin = 'noteSplashes/' + songJson.splashSkin;
```

---

## 3. `objects/Note.hx`

커스텀 스킨이 존재하지 않을 경우 기본 스킨으로 폴백 처리 추가

```haxe
// 변경 전
else skinPostfix = '';

// 변경 후
else {
    skinPostfix = '';
    if(skin != _lastValidChecked && !Paths.fileExists('images/' + path + skin + '.png', IMAGE)) {
        skin = defaultNoteSkin;
        _lastValidChecked = skin;
    }
}
```

---

## 4. `psychlua/DeprecatedFunctions.hx`

구버전 Lua 함수 6개 deprecated 래퍼 추가

```haxe
// 추가됨
Lua_helper.add_callback(lua, "getScore", function() { ... });
Lua_helper.add_callback(lua, "getMisses", function() { ... });
Lua_helper.add_callback(lua, "getHits", function() { ... });
Lua_helper.add_callback(lua, "changePresence", function(...) { ... });
Lua_helper.add_callback(lua, "getGlobalFromScript", function(luaFile, global) { ... });
Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile, global, val) { ... });
```

---

## 5. `psychlua/FunkinLua.hx`

**`triggerEvent` 파라미터 타입 변경**: `String` → `Dynamic` (숫자 등 다양한 타입 허용)

```haxe
// 변경 전
function(name:String, ?value1:String = '', ?value2:String = '')

// 변경 후
function(name:String, ?value1:Dynamic = null, ?value2:Dynamic = null)
var v1:String = (value1 != null) ? Std.string(value1) : '';
var v2:String = (value2 != null) ? Std.string(value2) : '';
```

**`getFlxEaseByString` 유틸 메서드 추가**

```haxe
public function getFlxEaseByString(?ease:String = ''):Dynamic {
    return LuaUtils.getTweenEaseByString(ease);
}
```

**HScript에 `runtimeShaders` 동기화 추가**

```haxe
if(PlayState.instance != null)
    PlayState.instance.runtimeShaders.set(name, [frag, vert]);
```

---

## 6. `psychlua/HScript.hx`

**HScript 컨텍스트에 유틸 클래스 추가**

```haxe
set('CoolUtil', backend.CoolUtil);
set('LuaUtils', psychlua.LuaUtils);
set('MusicBeatState', backend.MusicBeatState);
```

**패키지 없이 클래스명만 써도 자동 해석되는 폴백 패키지 목록 추가**

```haxe
var fallbackPackages:Array<String> = ['backend.', 'states.', 'objects.', 'psychlua.', 'shaders.', 'substates.'];
for (pkg in fallbackPackages) {
    c = Type.resolveClass(pkg + libName);
    if (c == null) c = Type.resolveEnum(pkg + libName);
    if (c != null) break;
}
```

---

## 7. `psychlua/LuaUtils.hx`

`getVarInArray`에서 배열 숫자 인덱스 접근 수정 (HXCPP에서 `target["0"]` 대신 `target[0]`)

```haxe
// 변경 전
var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
target = target[j];

// 변경 후
var j:String = splitProps[i].substr(0, splitProps[i].length - 1);
var jInt:Null<Int> = Std.parseInt(j);
target = (jInt != null) ? target[jInt] : Reflect.getProperty(target, j);
```

---

## 8. `psychlua/ReflectionFunctions.hx`

`getPropertyFromClass`/`setPropertyFromClass`에서 `backend.` 접두사 폴백 추가

```haxe
var myClass:Dynamic = Type.resolveClass(classVar);
if(myClass == null) myClass = Type.resolveClass('backend.' + classVar); // 추가됨
```

---

## 9. `psychlua/ShaderFunctions.hx`

**핵심 버그 수정**: `addLocalCallback` → `Lua_helper.add_callback` 변경
- 기존 `addLocalCallback`은 전역 콜백 테이블에 `null`을 저장 → Lua에서 호출 불가
- `initLuaShader`, `setSpriteShader` 두 함수 모두 수정

```haxe
// 변경 전
funk.addLocalCallback("initLuaShader", function(name:String) { ... });
funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) { ... });

// 변경 후
Lua_helper.add_callback(lua, "initLuaShader", function(name:String) { ... });
Lua_helper.add_callback(lua, "setSpriteShader", function(obj:String, shader:String) { ... });
```

**`setSpriteShader`에서 `StrumNote`의 `useRGBShader` 비활성화 추가**
- RGB 쉐이더가 커스텀 쉐이더를 덮어쓰는 문제 방지

```haxe
var leObjDyn:Dynamic = leObj;
if(Reflect.hasField(leObjDyn, 'useRGBShader'))
    Reflect.setProperty(leObjDyn, 'useRGBShader', false);
```

**`getShader`의 `Invalid Cast` 예외 수정**
- `RGBPaletteShader`가 붙어있을 때 `FlxRuntimeShader`로 캐스트 시 예외 발생

```haxe
// 변경 전
return cast (target.shader, FlxRuntimeShader);

// 변경 후
var sh = target.shader;
if (!(sh is FlxRuntimeShader)) return null;
return cast sh;
```

---

## 10. `states/PlayState.hx`

**모드차트용 tween/timer 관리 맵 추가**

```haxe
public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
```

일시정지/재개/종료 시 tween·timer 상태 처리 포함

**하위 호환 프로퍼티 추가**

```haxe
public var camFollowPos(get, never):FlxObject;
inline function get_camFollowPos():FlxObject return camFollow;

public var healthBarBG:FlxSprite;  // Bar.bg 참조
public var timeBarBG:FlxSprite;    // Bar.bg 참조
```

**`timeTxt` 접근 제한자 변경**

```haxe
// 변경 전
var timeTxt:FlxText;

// 변경 후
public var timeTxt:FlxText;
```
