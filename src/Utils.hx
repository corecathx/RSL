package;

/**
 * Utilization class for RSL.
 */
class Utils {
    public static function evalExp(expression:String, interp:Interp):Dynamic {
        expression = interp.parseVariables(expression, 0);
    
        Log.debug("Evaluating: " + expression);

        try {
            if (hasOperator(expression)) { // if we found an operator...
                Log.debug("Found operator, running arithmetic evaluation.");
                var result:Dynamic = evalArith(expression);
                Log.debug("Result: " + result); 
                return result;
            } else { // if not..
                var result:Float = Std.parseFloat(expression);
                if (result != null) {
                    Log.debug("Parsed Value: " + result); 
                    return result;
                } else {
                    Log.error({
                        line: -1,
                        message: "Invalid expression: " + expression
                    });
                    return null;
                }
            }
        } catch (e:Dynamic) {
            Log.error({
                line: -1,
                message: "Invalid arithmetic expression: " + expression
            });
            return null;
        }
    }
    
    // i want to exPLODE i'm not even a math expert
    public static function evalArith(expression:String):Dynamic {
        Log.debug("Starting arithmetic evaluation for: " + expression);
        
        expression = expression.replace(" ", "");
        
        var tokens:Array<String> = [];
        var curToken:String = "";  
        
        for (c in expression.split("")) {
            if (isOperator(c)) {
                if (curToken != "") {
                    tokens.push(curToken);
                    curToken = "";
                }
                tokens.push(c);
            } else {
                curToken += c;
            }
        }
        if (curToken != "") tokens.push(curToken); 
        
        Log.debug("Tokens after tokenization: " + tokens.join(", "));
        
        var intermediate:Array<String> = [];
        var i:Int = 0;
        
        while (i < tokens.length) {
            if (tokens[i] == "*" || tokens[i] == "/") {
                var left = Std.parseFloat(intermediate.pop());
                var right = Std.parseFloat(tokens[i + 1]);
                var result:Float = 0;
        
                if (tokens[i] == "*") {
                    result = left * right;
                } else if (tokens[i] == "/") {
                    if (right == 0) {
                        Log.error({
                            line: -1,
                            message: "Division by zero error in expression."
                        });
                        return null;
                    }
                    result = left / right;
                }
                intermediate.push(Std.string(result));
                i += 2;
            } else {
                intermediate.push(tokens[i]);
                i++;
            }
        }
        
        var result:Float = Std.parseFloat(intermediate[0]);
        
        for (i in 1...intermediate.length) {
            var op:String = intermediate[i];
            var number:Float = Std.parseFloat(intermediate[i + 1]);
            
            if (op == "+")
                result += number;
            else if (op == "-")
                result -= number;
        }
        return result;
    }    
    
    public inline static function isOperator(c:String):Bool
        return c == "+" || c == "-" || c == "*" || c == "/";

    public inline static function hasOperator(c:String):Bool
        return c.contains("+") || c.contains("-") || c.contains("*") || c.contains("/");

}