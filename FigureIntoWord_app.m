function FigureIntoWord_app(app,actx_word_p,hFig)
	% Capture current figure/model into clipboard:
    
    hgexport(hFig,'-clipboard') 
    
%     if isa(app,'double')
%         print -dmeta
%     else
%         hgexport(hFig,'-clipboard') 
%     end

	% Find end of document and make it the insertion point:
	end_of_doc = get(actx_word_p.activedocument.content,'end');
	set(actx_word_p.application.selection,'Start',end_of_doc);
	set(actx_word_p.application.selection,'End',end_of_doc);
	% Paste the contents of the Clipboard:
    %also works Paste(ActXWord.Selection)
	invoke(actx_word_p.Selection,'Paste');
    actx_word_p.Selection.TypeParagraph; %enter    
return