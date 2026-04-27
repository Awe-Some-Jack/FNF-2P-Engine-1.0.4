package backend;

class MemoryUtil
{
	public static function clearOpenFLUInt8Pools():Void
	{
		try
		{
			var uint8Buff:Class<Dynamic> = Type.resolveClass("openfl.display3D.utils.UInt8Buff");
			if (uint8Buff == null) return;

			var pools:Dynamic = Reflect.field(uint8Buff, "_pools");
			if (pools == null) return;

			var keys:Iterator<Dynamic> = cast Reflect.callMethod(pools, Reflect.field(pools, "keys"), []);
			for (key in keys)
			{
				var pool:Dynamic = Reflect.callMethod(pools, Reflect.field(pools, "get"), [key]);
				if (pool == null) continue;

				var clearMethod:Dynamic = Reflect.field(pool, "clear");
				if (clearMethod == null) continue;

				var cleared:Dynamic = Reflect.callMethod(pool, clearMethod, []);
				if (cleared != null)
					for (buffer in cast(cleared, Array<Dynamic>))
					{
						var destroyMethod:Dynamic = Reflect.field(buffer, "destroy");
						if (destroyMethod != null)
							Reflect.callMethod(buffer, destroyMethod, []);
					}
			}

			var clearPools:Dynamic = Reflect.field(pools, "clear");
			if (clearPools != null)
				Reflect.callMethod(pools, clearPools, []);
		}
		catch (e:Dynamic) {}
	}

	public static function clearMinor():Void
	{
		#if cpp
		cpp.vm.Gc.run(false);
		#end
	}

	public static function clearMajor():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		cpp.vm.Gc.compact();
		#end
	}
}
