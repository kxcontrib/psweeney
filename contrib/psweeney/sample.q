/Function and script to create random execution and quote tables

executions:([]time:`time$();sym:`symbol$();px:`float$();sz:`int$();side:`symbol$());
f:{i:.z.T; 
	j:rand[200.0];
	`executions insert(i;x;j;rand[5000];rand[`buy`sell]);
	do[10;`executions insert (i+1000;x;j+:(neg[5])+rand[10.];rand[5000];rand[`buy`sell]);i:i+1000;j+:(neg[5])+rand[10.]];
	};
 
f each -4?`GOOG`AAPL`IBM`PPPL;
executions:`time xasc executions;
quotes:([]sym:`symbol$();bid:`float$();ask:`float$());
`quotes insert (`GOOG`AAPL`MSFT`IBM`ABA`ARA`PPPL;99.7 94.6 100.03 95.7 96.4 99.7 98.4;100.2 100.07 96.7 98.4 100.4 98.9 99.0);

/Hard coded Table, demonstrating the difference between fifo and lifo (compare third and fourth line of table).
/It may be more useful in this example to omit `origsz`origpx`originalID from the deleted columns in pnl.q in order to see what the inventory contains at each stage.

simpleexecutions:([]time:`time$();sym:`symbol$();px:`float$();sz:`int$();side:`symbol$());
`simpleexecutions insert(12:00:00.000;`STOCK;200.0;50;`buy);
`simpleexecutions insert(12:00:01.000;`STOCK;205.0;75;`buy);
`simpleexecutions insert(12:00:02.000;`STOCK;207.5;100;`sell);
`simpleexecutions insert(12:00:03.000;`STOCK;198.0;50;`sell);

simplequotes:([]sym:`symbol$();bid:`float$();ask:`float$());
`simplequotes insert (`STOCK;202.5;203.0);

/
q)simpleexecutions
time         sym   px    sz  side
---------------------------------
12:00:00.000 STOCK 200   50  buy
12:00:01.000 STOCK 205   75  buy
12:00:02.000 STOCK 207.5 100 sell
12:00:03.000 STOCK 198   50  sell

/load pnl.q to get base functions
q)\l pnl.q

q)pnl[simpleexecutions;simplequotes;`fifo]
time         sym   px    sz  side id position originalID origpx   origsz TWpnl allpnl upnl rpnl  pnl
-------------------------------------------------------------------------------------------------------
12:00:00.000 STOCK 200   50  buy  0  50       ,0         ,200f    ,50    0     375    0    187.5 187.5
12:00:01.000 STOCK 205   75  buy  1  125      0 1        200 205f 50 75  0     -50    0    -25   -25
12:00:02.000 STOCK 207.5 100 sell 2  25       ,1         ,205f    ,25    500   0      0    250   250
12:00:03.000 STOCK 198   50  sell 3  -25      ,3         ,198f    ,25    -175  0      -125 -87.5 -212.5

q)pnl[simpleexecutions;simplequotes;`lifo]
time         sym   px    sz  side id position originalID origpx   origsz TWpnl allpnl upnl rpnl  pnl
------------------------------------------------------------------------------------------------------
12:00:00.000 STOCK 200   50  buy  0  50       ,0         ,200f    ,50    0     137.5  0    68.75 68.75
12:00:01.000 STOCK 205   75  buy  1  125      0 1        200 205f 50 75  0     187.5  0    93.75 93.75
12:00:02.000 STOCK 207.5 100 sell 2  25       ,0         ,200f    ,25    375   0      0    187.5 187.5
12:00:03.000 STOCK 198   50  sell 3  -25      ,3         ,198f    ,25    -50   0      -125 -25   -150
/