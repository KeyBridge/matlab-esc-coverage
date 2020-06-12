function WordSymbol_app(app,actx_word_p,symbol_int_p)
    % symbol_int_p holds an integer representing a symbol, 
    % the integer can be found in MSWord's insert->symbol window    
    % 176 = degree symbol
    actx_word_p.Selection.InsertSymbol(symbol_int_p);
return