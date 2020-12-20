:-use_module(library(clpfd)).
:-use_module(library(lists)).

:-consult('restrictions.pl').
:-consult('utils.pl').

lb :- 
   testBoard(NBoard),
   write('ORIGINAL ------'), nl,
   printMatrix(NBoard),

   % bagof(ResultBoard, lightbulb(NBoard, ResultBoard), Ret),
   setof(ResultBoard, lightbulb(NBoard, ResultBoard), List),
   showResults(List, NBoard).

   % separator,
   % showResult(NBoard, ResultBoard).

lb :-
   write('No results found!').

%testBoard([[1, 1, 1], [1, 1, 1]]). %Example where no option is valid
testBoard([[3, 3, 5, 2],[4, 6, 3, 3], [2, 3, 5, 5], [2, 4, 4, 4]]). %Solved example at the top; Has multiple solutions
% testBoard([[2, 4, 4, 3],
%            [4, 3, 6, 4], 
%            [4, 8, 6, 6], 
%            [2, 3, 4, 3]]). %First example



lightbulb(NumbersBoard, ResultBoard) :-
   length(NumbersBoard, Collen),
   getRowLength(NumbersBoard, RowLen),
   length(ResultBoard, Collen),
   createMatrix(ResultBoard, RowLen),
   flatten(ResultBoard, FlattenedResults), %Get the flattened lists, since it's easier and more efficient to work with them
   flatten(NumbersBoard, FlattenedNumbers), %Get the flattened lists, since it's easier and more efficient to work with them
   domain(FlattenedResults, 0, 1), %1 is lit, 0 is unlit
   %Temporary test code

   sum(FlattenedResults, #\=, 0), %Exclude all zeros
        
   restrictSpot(FlattenedNumbers, FlattenedResults, Collen, RowLen, 1),
    write('.'),
   labeling([], FlattenedResults).

/* SHOW RESULTS --------------------------------------------------*/
showResults([], _).
showResults([First|Rest], Original) :-
   separator,
   showResult(Original, First),
   showResults(Rest, Original).

showResult([], []).
showResult([OriginalHead | OriginalRest], [OnHead | OnRest]) :-
   nl, write('| '), showResultLine(OriginalHead, OnHead),
   separator,
   showResult(OriginalRest, OnRest).

showResultLine([], []).
showResultLine([FirstOriginal | RestOriginal], [FirstRes | RestRes]) :-
   FirstRes =:= 1,
   format('~p | ', [FirstOriginal]),
   showResultLine(RestOriginal, RestRes).

showResultLine( [_ | RestOriginal], [_|RestRes]) :-
   write('  | '),
   showResultLine(RestOriginal, RestRes).