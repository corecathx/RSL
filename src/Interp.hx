package;

import sys.FileSystem;
import sys.io.File;
import Log;

class Interp {
    public var content:String = "";
    public var variables:Map<String, Dynamic> = [];

    /**
     * Initialize a new Interp instance.
     */
    public function new() {
        // do something here later
    }

    /**
     * Execute a RSL script.
     * @param path Path to the file.
     */
    public function execute(path:String):Void {
        if (!FileSystem.exists(path)) {
            Sys.println("File not found: " + (Sys.getCwd() + path));
            return;
        }

        if (FileSystem.isDirectory(path)) {
            Sys.println((Sys.getCwd() + path) + " is a directory. ");
            return;
        }
        var _file:String = File.getContent(path).trim();
        Log.debug(_file);
        for (index=>line in _file.split('\n')) {
            line = line.trim();
            var commentIndex:Int = line.indexOf("#");
            if (commentIndex != -1)
                line = line.substring(0, commentIndex).trim(); 
    
            if (line == "") 
                continue;

            if (line.startsWith("declare")) { // a variable.
                var parts:Array<String> = line.split(" ");
                if (parts.length == 1) {
                    Log.error({
                        line: index+1, 
                        message: "Attempted to declare a variable without identifier"
                    });
                    break;
                } else if (parts.length == 2) {
                    variables.set(parts[1], null);
                    Log.debug("Append Variable // " + parts[1] + ': ' + variables.get(parts[1]));
                } else if (parts.length == 3) {
                    if (parts[2] == "to") {
                        Log.error({
                            line: index+1, 
                            message: "Malformed variable declaration"
                        });
                    } else {
                        Log.error({
                            line: index+1, 
                            message: "Invalid syntax \""+parts[2]+"\""
                        });
                    }
                    break; 
                } else if (parts.length >= 4) { 
                    if (parts.length > 4) {
                        var firstQuote:Int = line.indexOf("\"");
                        var lastQuote:Int = line.lastIndexOf("\"");
                        var filter:String = line.substring(firstQuote+1, lastQuote);
                        if (firstQuote != lastQuote) {
                            variables.set(parts[1], filter);
                            Log.debug("Append Variable // " + parts[1] + ' -> ' + variables.get(parts[1]));
                        } else if (Utils.hasOperator(parts.slice(3).join(" "))){
                            var expression:String = parts.slice(3).join(" ");
                            var evaluatedValue = Utils.evalExp(expression, this);
                            if (evaluatedValue != null) {
                                variables.set(parts[1], evaluatedValue);
                                Log.debug("Append Variable // " + parts[1] + ' -> ' + variables.get(parts[1]));
                            } else {
                                Log.error({
                                    line: index+1, 
                                    message: "Invalid arithmetic expression"
                                });
                            }
                        } else {
                            Log.error({
                                line: index+1, 
                                message: "Malformed variable declaration"
                            });
                        }
                    } else {
                        variables.set(parts[1], parts[3]);
                        Log.debug("Append Variable // " + parts[1] + ' -> ' + variables.get(parts[1]));
                    }
                }
            } else if (line.startsWith("output")) { // output, like print
                var parsed:String = line.replace("output", "").trim();
                var firstQuote:Int = parsed.indexOf("\"");
                var lastQuote:Int = parsed.lastIndexOf("\"");
                if (firstQuote != lastQuote) {
                    parsed = parsed.substring(firstQuote+1, lastQuote);
                } else {
                    Log.error({
                        line: index+1, 
                        message: "Invalid output usage"
                    });
                    break;
                }
                parsed = parseVariables(parsed);
                Log.output({
                    line: index+1,
                    message: parsed
                });
            } else if (line.startsWith("#")){ // comment
                // we found a comment!
            } else if (line != "") { // anything, we call it invalid
                line = line.trim();
                Log.error({
                    line: index+1, 
                    message: line.split(" ")[0] + " is invalid"
                }); 
                break;
            }
        }
    }

    public function parseVariables(string:String):String {
        for (key in variables.keys())
            string = string.replace("$"+key, Std.string(variables.get(key)));
        return string;
    }
}