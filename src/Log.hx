package;

class Log {
    public static var DEBUG_ENABLED:Bool = false;
    public static function debug(data:Dynamic) {
        if (!DEBUG_ENABLED) return;
        var dataFix:String = Std.string(data);
        var lines:Array<String> = dataFix.split('\n');
        for (index => line in lines) {
            Sys.println("[RSL.DEBUG] ["+index+"] > " + line);
        }
    }

    public inline static function error(data:LineReport) {
        Sys.println("[RSL.ERROR] > " + data.message + " at line " + data.line + ".");
    }

    public inline static function output(data:LineReport) {
        Sys.println("[RSL.OUTPUT] > " + data.message + " (line " + data.line + ")");
    }
}

typedef LineReport = {
    line:Int,
    message:String
}