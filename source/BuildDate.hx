package;

import haxe.macro.Context;
import haxe.macro.Expr;

class BuildDate
{
	// 컴파일 시점의 날짜/시간을 문자열로 반환하는 매크로
	public static macro function get():ExprOf<String>
	{
		var date = Date.now();
		var y  = date.getFullYear();
		var mo = pad(date.getMonth() + 1);
		var d  = pad(date.getDate());
		var h  = pad(date.getHours());
		var mi = pad(date.getMinutes());
		var s  = pad(date.getSeconds());
		var str = '$y-$mo-$d $h:$mi:$s';
		return macro $v{str};
	}

	static function pad(n:Int):String
	{
		return n < 10 ? '0$n' : '$n';
	}
}
