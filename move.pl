
executePlayerTurn(Board, Player, UpdatedBoard) :-
        getPlayerColor(Player, Color),
        repeat,
                once( inputType(Color, Move)),   % input first move),
                getNth(0, Move, Type),
                (isRingMove(Type) ->     % if first move was a ring move, the player can move one of his balls
                 (
                    checkRingStash(Type, Player),
                    move(Board, Move, TmpBoard),
                    repeat,
                        moveBallAfterRing(TmpBoard, Move, Color, UpdatedBoard)
     
                 );
                isBallMove(Type) ->
                 (
                        moveBall(Board, Color, Move, UpdatedBoard)
                     
                 )).

checkRingStash('MR',_).              
checkRingStash('R', Player) :-
    getStashSize(Player, Size),
    Size > 0.

checkRingStash(_) :- nl, write('[X] No available rings'), nl, fail.
        
                                
/* SECOND MOVE --------------------------------------*/                             
                                             
% get coordinates of the previously placed ring                       
getRingDestCoords(['R',_,DestLine,DestCol], DestLine, DestCol).                           
getRingDestCoords(['MR',_,_,_, DestLine, DestCol], DestLine, DestCol).

% choose and move a ball to the cell with the previously placed ring                               
moveBallAfterRing(Board, RingMove, Color, NewBoard) :-
        (askForSecondMove ->
                ( % execute second move
                    (
                          once(inputBallMove(Color, BallMove)),       % get ball location
                          getNth(2, BallMove, BallY), 
                          getNth(3, BallMove, BallX),
                          getTopXY(Board, BallX, BallY, Top), !,
                          isBall(Top),                                % input location must be a ball
                          getRingDestCoords(RingMove, DestLine, DestCol),
                          append(BallMove, [DestLine, DestCol], NewMove), !,
                          moveBall(Board, Color, NewMove, NewBoard)
                    );
                       
                        (nl, write('[X] Could not execute secondMove'), nl,
                        fail)
                ); % move on
                % no move executed
                % assign previous board to new one
                append(_, Board, NewBoard)
        ).
        
                                        
isRingMove('MR').
isRingMove('R').
isBallMove('MB').

validAnswer('yes', y).
validAnswer('no', n).
validAnswer(y, y).
validAnswer(n, n).

% false if no, true if yes
askForSecondMove :-
     repeat,
        once(inputString('Move a ball? (yes/no)', Answer)),     
        validAnswer(Answer, Value),         %validate input
        !,
        (Value == y);
        fail.

/*--------------------------------------------- VAULTS ---------------------------------------*/ 

isEnemyBall(white, bb).
isEnemyBall(black, wb).

getAllCoords([_,_,SrcLine,SrcCol,DestLine,DestCol], SrcLine, SrcCol, DestLine, DestCol).

% verify if vault call is necessary                    
moveBall(Board,_, Move, UpdatedBoard) :-
         once(getAllCoords(Move, SrcLine, SrcCol, DestLine, DestCol)),
        \+isVault(SrcLine, SrcCol, DestLine, DestCol),
        !, % if not a vault, list of moves is the move itself
        move(Board, Move, UpdatedBoard).

% in case it is a vault
moveBall(Board, Color, Move, UpdatedBoard) :-

        nl, write(' [i] Movement requires vault'),nl,
        getAllCoords(Move, SrcLine, SrcCol, DestLine, DestCol),
        fetchVaultedBalls(Board, Color, SrcLine, SrcCol, DestLine, DestCol, CoordsList),
        !,
        write(CoordsList),
        (length(CoordsList, 0) ->       % only call vaul assistant is there are balls to displace
                (move(Board, Move, UpdatedBoard));
                (move(Board, Move, TmpBoard), !,
                executeVaultMoves(TmpBoard, CoordsList, Move, UpdatedBoard))).

printVaultList([]).
printVaultList([Head|Rest]) :-
        getNth(0, Head, Line),
        getNth(1, Head, Col),
        C is Col+1,
        getAlpha(Line, Letter),
        format('| ~p~p ', [Letter, C]),
        printVaultList(Rest).

getBallAt(Board, List, Index, SrcLine, SrcCol, Ball) :-
        getNth(Index, List, [SrcLine, SrcCol]),
        getTopXY(Board, SrcCol, SrcLine, Ball).

pickRelocation(Board, CoordsList, UpdatedCoordsList, UpdatedBoard) :-
    once(length(CoordsList, L)),
    inputListIndex(L, Index),
    getBallAt(Board, CoordsList, Index, SrcLine, SrcCol, Ball),
    inputMove('RB', _, Destination),
    append(['RB', Ball, SrcLine, SrcCol], Destination, Relocate), !,   % build relocate move
    isValidBallRelocation(Board, Relocate),                         % validate player relocation input
    executeMove('RB', Board, Relocate,  UpdatedBoard),
    deleteNth(Index, CoordsList, UpdatedCoordsList).


 
       
% if the vaulted balls list is empty then no vault is performed
executeVaultMoves(UpdatedList, List, _, UpdatedList) :- length(List,0).

% the initial ball move is only called at the end of all the intermidiate vaults
executeVaultMoves(Board, CoordsList, Move, UpdatedBoard) :-
        nl, write(' [i] You must relocate each of the balls listed bellow'), nl,
        printVaultList(CoordsList), nl,
        copy_term(CoordsList, TmpList),
        pickRelocation(Board, TmpList, NewList, TmpBoard), !,
        executeVaultMoves(TmpBoard, NewList, Move, UpdatedBoard).        
            

/* fetch vaulted balls*/             
% horizontal vaults
fetchVaultedBalls(Board, Color, SrcLine, SrcCol, DestLine, DestCol, Vaulted) :-
    SrcLine =:= DestLine,
    searchStep(SrcCol, DestCol, Step),
    selectLine(Board, SrcLine, Line),
    fetchHorizontal(Line, SrcLine, Color, SrcCol, DestCol, Step, Vaulted).

%vertical vaults
fetchVaultedBalls(Board, Color, SrcLine, SrcCol, DestLine, DestCol, Vaulted) :-
    SrcCol =:= DestCol,
    searchStep(SrcLine, DestLine, Step),
    fetchVertical(Board, Color, SrcLine, DestLine, SrcCol, Step, Vaulted).

% diagonal Vaults
fetchVaultedBalls(Board, Color, SrcLine, SrcCol, DestLine, DestCol, Vaulted) :-
    searchStep(SrcCol, DestCol ,StepX),
    searchStep(SrcLine, DestLine, StepY),
    fetchDiagonal(Board, Color, SrcLine, SrcCol, DestLine, DestCol, StepY, StepX, Vaulted).


/* FETCH HORIZONTAL ----------------------*/
% reached target cell
fetchHorizontal(_, _, _, SrcCol, DestCol, Step, []) :- 
    SrcCol+Step =:= DestCol.

% horizontal search
% if current top ball is opponents ball add it to the vaulted list
fetchHorizontal(Line, LineIndex,  Color, SrcCol, DestCol, Step, [Head|Final]) :-
    once( % selecting current top ball
            (
              Col is SrcCol+Step,
              selectCell(Line, Col, Cell),
              getTop(Cell, Top)
            )
        ),                       
    isEnemyBall(Color, Top), % checking if it's one of the opponent's ball
    append(_, [LineIndex, Col], Head),
    fetchHorizontal(Line, LineIndex, Color, Col, DestCol, Step, Final).

% if not continue
fetchHorizontal(Line, LineIndex,  Color, SrcCol, DestCol, Step, Final) :-
    Col is SrcCol+Step,
    fetchHorizontal(Line, LineIndex, Color, Col, DestCol, Step, Final).


/* FETCH VERTICAL ------------------------*/
% reached target cell
fetchVertical(_, _, SrcLine, DestLine, _, Step, []):-
        SrcLine+Step =:= DestLine.
% vertical search
% if current top ball is opponents ball add it to the vaulted list
fetchVertical(Board, Color, SrcLine, DestLine, Col, Step, [Head|Rest]) :-
    once(
            (
                Y is SrcLine+Step,
                selectLine(Board, Y, Line),
                selectCell(Line, Col, Cell),
                getTop(Cell, Top)
            )
        ),
    isEnemyBall(Color, Top),
    append(_, [Y, Col], Head),
    fetchVertical(Board, Color, Y, DestLine, Col, Step, Rest).

% if not continue
fetchVertical(Board, Color, SrcLine, DestLine, Col, Step, List):-
    Y is SrcLine+Step,
    fetchVertical(Board, Color, Y, DestLine, Col, Step, List).


/* FETCH DIAGONAL ----------------------------------*/  
/*diagonal vault verification*/
%reached target cell
fetchDiagonal(_, _, SrcLine, _, DestLine, _, StepY, _, []) :-
    SrcLine+StepY =:= DestLine.
%diagonal search
fetchDiagonal(Board, Color, SrcLine, SrcCol, DestLine, DestCol, StepY, StepX, [Head|Rest]) :-
    once(
        (
            Y is SrcLine+StepY,
            X is SrcCol+StepX,
            selectLine(Board, Y, Line),
            selectCell(Line, X, Cell),
            getTop(Cell, Top)
        )
    ),
    isEnemyBall(Color, Top),
    append(_, [Y, X], Head),
    fetchDiagonal(Board, Color, Y, X, DestLine, DestCol, StepY, StepX, Rest).

fetchDiagonal(Board, Color, SrcLine, SrcCol, DestLine, DestCol, StepY, StepX, List) :-
      Y is SrcLine+StepY,
      X is SrcCol+StepX,  
      fetchDiagonal(Board, Color, Y, X, DestLine, DestCol, StepY, StepX, List).                                            
        
        
