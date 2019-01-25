function str = strLib( stringID )
%STRLIB A library collection of common strings and tooltips organized for easy
%readability.

switch stringID
  case 'normSwitch'
    str = 'Perform scaling based on rules set in preferences.';
  case 'currentEpoch'
    str = 'The index number of the first visible datum.';
  case 'keyboardRules'
    str = [ ...
      'var styleNode = document.createElement(''style'');', ...
      'styleNode.innerHTML = ''', ...
      '.aside {\n', ...
      '  font-size: 17px !important;\n', ...
      '  height: 320px !important;\n', ...
      '  width: 405px !important;\n', ...
      '  line-height: 22px !important;', ...
      '  font-family: "Times New Roman", Times, serif;\n',...
      '}\n', ...
      '.aside h2 {\n', ...
      '  margin-top: 10px;\n', ...
      '}\n', ...
      '.aside hr {\n', ...
      '  margin: 2px 0px 5px;\n', ...
      '}\n', ...
      'kbd {\n',...
      '  display: inline-block;\n',...
      '  padding: 2px 7px;\n',...
      '  line-height: 23px;\n',...
      '  color: #444d56;\n',...
      '  vertical-align: middle;\n',...
      '  background-color: #fafbfc;\n',...
      '  border: solid 1px #c6cbd1;\n',...
      '  border-bottom-color: #959da5;\n',...
      '  border-radius: 3px;\n',...
      '  box-shadow: inset 0 -1px 0 #959da5;\n',...
      '  font: 20px "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace;\n',...
      '}\n'';', ...
      'document.head.appendChild(styleNode);' ...
      ];
  case 'keyboardHTML'
    str = [ ...
      '<h2>Navigation</h2>\n<hr>\n', ...
      '<p><kbd>&larr;</kbd>, <kbd>&rarr;</kbd>: Navigate by small epoch steps.</p>\n',...
      '<p><kbd>&uarr;</kbd>, <kbd>&darr;</kbd>: Overlay by small overlay steps.</p>\n',...
      '<p><kbd>Shift</kbd> + <kbd>&larr;,&rarr;,&uarr;,&darr;</kbd>: Use big step.</p>\n',...
      '<p><kbd>Home</kbd>, <kbd>End</kbd>: First / Last record.</p>\n',...
      '<h2>Display Toggles</h2>\n<hr>\n', ...
      '<p><kbd>Alt</kbd>+<kbd>F</kbd>: Toggle filter.</p>\n',...
      '<p><kbd>Alt</kbd>+<kbd>S</kbd>: Toggle statistics.</p>\n',...
      '<p><kbd>Alt</kbd>+<kbd>B</kbd>: Toggle baseline</p>\n',...
      '<p><kbd>X</kbd>: Toggle inclusion of current epoch.</p>\n',...
      '<h2>Menu Actions</h2>\n<hr>\n', ...
      '<p><kbd>Ctrl</kbd>+<kbd>N</kbd>: Load a new supported datafile..</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>O</kbd>: Open a saved Session.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>S</kbd>: Save the current Session.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>Q</kbd>: Quit Program.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>I</kbd>: View current file information.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>N</kbd>: View digital notes.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>P</kbd>: View epoch protocols or settings.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>D</kbd>: Open analysis interface.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>M</kbd>: Send to MATLAB Workspace.</p>\n',...
      '<p><kbd>Ctrl</kbd>+<kbd>H</kbd>: View documentation.</p>\n',...
      '<h2>Miscellaneous Actions</h2>\n<hr>\n', ...
      '<p><kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>P</kbd>: Take screenshot.</p>\n',...
      '<br>\n' ...
      ];
  case 'analysisReadme'
    str =       {[ ...
        {'% ENTER ANALYSIS DESCRIPTIONS HERE'}; ...
        {'%'}; ...
        {'% ----------------------------------------------------------------------- %'}; ...
        {'% README!!!'}; ...
        {'% ---------- %'}; ...
        {'% This template has a special syntax for Iris.'}; ...
        {'%'}; ...
        {'% It is always best to put some sort of description in the header of'}; ...
        {'% the analysis function so that you, and/or others, can understand the'}; ...
        {'% purpose of the function as well as all the arguments (input and output).'}; ...
        {'% It is also very good practice to keep a log of changes and notes related'}; ...
        {'% to the function''s purpose up here.'}; ...
        {'%'}; ...
        {'% First, we must have Data as the first argument to the function. This'}; ...
        {'% argument will be of class irisData, the file should be on your MATLAB'}; ...
        {'% path so you can use it without running Iris in a later MATLAB session.'}; ...
        {'% This object has a few convenience methods builtin that help you perform'}; ...
        {'% common tasks such as averaging groups of epochs. For a detailed'}; ...
        {'% description of the included mehtods, see doc(''Iris'').'}; ...
        {'%'}; ...
        {'% Next, any input can have, but doesn''t require, default values which'}; ...
        {'% we can set in a special syntax, shown below. Briefly, using the block'}; ...
        {'% comment tags %{...%}, and the definition sign, a colon followed by an'}; ...
        {'% equals sign, we can set default values. '}; ...
        {'%'}; ...
        {'% It is important that 1) argument default names are case-sensitive and'}; ...
        {'% MUST match the argument name in the function definition line and 2) must'}; ...
        {'% be valid MATLAB expressions, that is, if you need it to be a char vector,'}; ...
        {'% then you must wrap the text in single quotes. Note that spaces are'}; ...
        {'% ignored but each definition MUST ONLY BE ONE LINE. The parser will ignore'}; ...
        {'% any line breaks and using the MATLAB newline syntax, ..., will break the'}; ...
        {'% parser.'}; ...
        {'%'}; ...
        {'% --- SET YOUR DEFAULTS BELOW --- %'}; ...
        {'%{'}; ...
        {'DEFAULTS'} ...
      ]; ...
      [ ...
        {'%}'}; ...
        {'%'}; ...
        {'% ----------------------------------------------------------------------- %'}; ...
        {''}; ...
        {'%% Begin Analysis'}; ...
        {'% Use the Data object, see doc(''IrisData'')'}; ...
        {''}; ...
        {''}; ...
        {''}; ...
        {''}; ...
      ]; ...
      [ ...
        {'end % End of analysis'} ...
      ]};
  otherwise
    %convert string ID from camel to sentence case.
    str = regexprep(stringID, '(?<=[a-z])[A-Z]', ' $0');
    str = regexprep(str, '(?<=\s)[A-Z](?![A-Z])', '${lower($0)}');
    str = regexprep(str, '^.', '${upper($0)}');
end

end
