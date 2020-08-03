function PrintMethods_app(app,actx_word_p,category_p)
    style='Heading 3';
    text=strcat(category_p,'-methods');
    WordText_app(app,actx_word_p,text,style,[1,1]);           
    
    style='Normal';    
    text=strcat('Methods called from Matlab as: ActXWord.',category_p,'.MethodName(xxx)');
    WordText_app(app,actx_word_p,text,style,[0,0]);           
    text='Ignore the first parameter "handle". ';
    WordText_app(app,actx_word_p,text,style,[1,3]);           
    
    MethodsStruct=eval(['invoke(actx_word_p.' category_p ')']);
    MethodsCell=struct2cell(MethodsStruct);
    NrOfFcns=length(MethodsCell);
    for i=1:NrOfFcns
        MethodString=MethodsCell{i};
        WordText_app(app,actx_word_p,MethodString,style,[0,1]);           
    end
return