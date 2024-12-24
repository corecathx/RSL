package;

class Main {
    public static function main():Void {
        Sys.setCwd("../root");

        var interp:Interp = new Interp();
        interp.execute("code.rsl");
    }
}
