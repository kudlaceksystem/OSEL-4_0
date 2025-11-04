function keyShort = keyShortTbl
commandShortcut = {...
    'prevNonEmptyLabelFile','b',            'control'; % Buttons in control window, keep these together and in the order of the buttons
    'prevSigWNonEmptyLabel','b',            '';
    'saveLblPrevFile',      'z',            '';
    'jumpToStart',          'home',         '';
    'pageBackward',         'x',            '';
    'backward',             'leftarrow',    '';
    'playPause',            'space',        ''; % Toggle between play and pause
    'stop',                 'r',            ''; % Returns to the previous now location
    'forward',              'rightarrow',   '';
    'pageForward',          'c',            '';
    'jumpToEnd',            'end',          '';
    'saveLblNextFile',      'v',            '';
    'nextSigWNonEmptyLabel','n',            '';
    'nextNonEmptyLabelFile','n',            'control';
    'cycleLabelClassToEdit','a',            '';
    'autoPageForward',      'space',        'control';
    
    'prevFile',             'pageup',       ''; % Alternative shortcuts for next and prev file
    'nextFile',             'pagedown',     '';
    'saveLblPrevFile',      'y',            ''; % So that it works also on Czech keyboard
    'horizontalZoomIn',     'rightarrow',   'shift'; % Zoom buttons in the signal window, keep them together
    'horizontalZoomOut',    'leftarrow',    'shift';
    'verticalZoomIn',       'uparrow',      'control';
    'verticalZoomOut',      'downarrow',    'control';
    'pageBackward',         'leftarrow',    'control';
    'pageForward',          'rightarrow',   'control';
    'mouseZoomIn',          'shift',        'shift'; % Click and drag zoom function
    'mouseZoomOut',         'control',      'control';
    'mouseZoomEscape',      'escape',       '';
    'mouseMeasure',         'alt',          'alt'; % Click and drag measure function
    'horizontalZoomIn',     'r',            'control'; % Alternative shortcuts for zooming according to Spike2 (check the direction if it's correct)
    'horizontalZoomOut',    'e',            'control';
    'horizontalZoomIn',     'r',            'shift'; % Alternative shortcuts for zooming according to Spike2 (check the direction if it's correct)
    'horizontalZoomOut',    'e',            'shift';
    'verticalZoomIn',       'f',            'control';
    'verticalZoomOut',      'd',            'control';
    'decreasePlaySpeed',    'q',            ''; % Play speed control
    'increasePlaySpeed',    'w',            '';
    'decreasePlaySpeed',    'subtract',     ''; % Alternative shortcuts for play speed control
    'increasePlaySpeed',    'add',          '';
    'labelDelete',          'delete',       '';
    'labelUndo',            'z',            'control';
    'labelSave',            'l',            '';
    'labelSave',            's',            'control';
    'editCurrentFileFocus', 'f6',           '';
    'toggleBipolar',        'f2',           '';
    
    'numberPressed',        '0',            ''; % For labeling. Keep this as numbers unless you want to make major changes to the code.
    'numberPressed',        '1',            '';
    'numberPressed',        '2',            '';
    'numberPressed',        '3',            '';
    'numberPressed',        '4',            '';
    'numberPressed',        '5',            '';
    'numberPressed',        '6',            '';
    'numberPressed',        '7',            '';
    'numberPressed',        '8',            '';
    'numberPressed',        '9',            'control';
    'easterEgg01',          'r',            'control+shift';
    'moveSigToFolder',      'm',            '';
    };

%% Other controls implemented withing respective function:
% Scroll wheel ... pan
% control+scroll wheel ... vertical zoom
% shift+scroll wheel ... horizontal zoom

Command = string(commandShortcut(:, 1));
Shortcut = string(commandShortcut(:, 2));
Modifier = string(commandShortcut(:, 3));
keyShort = table(Command, Shortcut, Modifier);
end



