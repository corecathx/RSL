package;

import sys.FileSystem;
import sys.io.File;
import Log;

class Interp {
    public var content:String = "";
    public var variables:Map<String, Dynamic> = [];
    public var error:Bool = false;
    var insideFunction:Bool = false;

    /**
     * Initialize a new Interp instance.
     */
    public function new() {
        // do something here later
        setVar("system", {
            name: Sys.systemName()
        });
    }

    public function setVar(key:String, val:Dynamic) {
        variables.set(key, val);
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

        error = false;
        var _file:String = File.getContent(path);
        for (index=>line in _file.split('\n')) {
            if (error) 
                break;

            var commentIndex:Int = line.indexOf("#");
            if (commentIndex != -1)
                line = line.substring(0, commentIndex).trim(); 

            if (line == "") 
                continue;

            // Only check indentation if not inside a function body
            if (!insideFunction && Utils.getIndentLevel(line) > 0) {
                Log.error({
                    line: index + 1, 
                    message: "Unexpected indentation"
                });
                return;
            }

            if (line.startsWith("declare")) { // a variable.
                handleDeclare(line, index);
            } else if (line.startsWith("output")) { // output, like print
                handleOutput(line, index);
            } else if (line.startsWith("func")) {
                handleFunction(line, _file.split('\n'), index);
            } else if (line.startsWith("#")) { // comment
                // we found a comment!
            } else if (line.trim() != "") { // anything, we call it invalid
                line = line.trim();
                Log.error({
                    line: index + 1, 
                    message: line.split(" ")[0] + " is invalid"
                }); 
                break;
            }
        }
    }

    public function parseVariables(string:String, index:Int):String {
        for (key in variables.keys()) {
            var regex:EReg = new EReg("\\$" + key + "(?:\\.[a-zA-Z_][a-zA-Z0-9_]*)*", "g");
    
            if (regex.match(string)) {
                var m:String = regex.matched(0);
                var match:Array<String> = m.substring(1,m.length).split(".");
                var field:String = "";
                for (i in 1...match.length) {
                    field += '${match[i]}.';
                }
                field = field.substring(0, field.length-1);
                try {
                    if (!Reflect.hasField(variables.get(match[0]), field)) {
                        //string = string.replace(m, "null");
                    } else {
                        string = string.replace(m, Std.string(Reflect.getProperty(variables.get(match[0]), field)));
                    }
                    
                } catch(e) {
                    Log.error({
                        line: index+1, 
                        message: e.message
                    });
                    error = true;
                    return string;
                }
            }
        
            string = string.replace("$" + key, Std.string(variables.get(key)));
        }
        return string;
    }
    

    function handleDeclare(line:String, index:Int = 0) {
        var parts:Array<String> = line.split(" ");
        if (parts.length == 1) {
            Log.error({
                line: index+1, 
                message: "Attempted to declare a variable without identifier"
            });
            error = true;
            return;
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
            error = true;
            return;
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
                        return;
                    }
                } else {
                    Log.error({
                        line: index+1, 
                        message: "Malformed variable declaration"
                    });
                    return;
                }
            } else {
                variables.set(parts[1], parts[3]);
                Log.debug("Append Variable // " + parts[1] + ' -> ' + variables.get(parts[1]));
            }
        }
    }

    function handleOutput(line:String, index:Int = 0) {
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
            error = true;
            return;
        }
        parsed = parseVariables(parsed, index);
        Log.output({
            line: index+1,
            message: parsed
        });
    }

    function handleFunction(line:String, lines:Array<String>, index:Int) {
        var lineSplit:Array<String> = line.replace("func", "").trim().split(" ");
        if (lineSplit.length > 1) {
            Log.error({
                line: index + 1, 
                message: "Malformed function syntax"
            });
            error = true;
            return;
        } else {
            var firstParent:Int = line.trim().indexOf("(");
            var lastParent:Int = line.trim().lastIndexOf(")");
            var endsWithColon:Bool = line.trim().endsWith(":");

            if (firstParent == -1 || lastParent == -1) {
                Log.error({
                    line: index + 1, 
                    message: "Malformed function syntax"
                });
                error = true;
                return;
            } else if (!endsWithColon) {
                Log.error({
                    line: index + 1, 
                    message: "Missing \":\""
                });
                error = true;
                return;
            } else {
                var funcName:String = line.substring(0, firstParent).trim();
                var args:Array<String> = line.substring(firstParent + 1, lastParent).split(",").map(function(arg:String):String {
                    return arg.trim();
                });

                Log.debug("Function declared: " + funcName + " with arguments: " + args.join(", "));


                insideFunction = true;

                var body:Array<String> = [];
                var bodyIndentLevel:Int = Utils.getIndentLevel(lines[index + 1]);

                var bodyStartIndex:Int = index + 1;
                while (bodyStartIndex < lines.length) {
                    var bodyLine:String = lines[bodyStartIndex].trim();

                    var indentLevel = Utils.getIndentLevel(lines[bodyStartIndex]);
                    if (indentLevel <= 0) {
                        break;
                    }

                    body.push(bodyLine);
                    bodyStartIndex++;
                }

                variables.set(funcName, {
                    args: args,
                    body: body
                });
                Log.debug("Function body: " + body.join("\n"));
            }
        }
    }
}