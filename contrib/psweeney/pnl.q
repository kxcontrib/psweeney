/The pnl function takes three inputs - executions table (with columns sym, px, sz and side), mktrate table (sym, bid and ask columns) and the trading principle used - `fifo or `lifo.
/It outputs a new table containing the various pnls for individual trades, by sym.

inventory:{[x;pos;sd;px;sz;id;method]$[$[`buy=sd;>;<][0;pos];
			[   $[method=`lifo;remsz:reverse deltas 0|reverse[reverse sums reverse[x`origsz]]-sz;method=`fifo;remsz:deltas 0|sums[x`origsz]-sz;"invalid argument"];
				rp:$[`buy=sd;-1;1]*(sum[tradesz]*px)-sum x[`origpx]*tradesz:x[`origsz]-remsz;
				n:sum remsz within -.0001 .0001;m:sum not tradesz within -.0001 .0001;if[method=`lifo;n:neg n;m:neg m;];
				x:update origpx:_[n;origpx],origsz:_[n;remsz],originalID:_[n;originalID],TWpnl:rp,TradedWith:m#originalID,TWprice:m#px,TWsize:m#tradesz from x;
				if[0.001<sz-:sum tradesz;x:update origpx:(origpx,px),origsz:(origsz,sz),originalID:(originalID,id)from x]];
			x:update TWpnl:0f,TradedWith:(),TWprice:(),TWsize:() from update originalID:(originalID,id),origpx:(origpx,px),origsz:(origsz,sz)from x];x}

/The analysis function uses the inventory function to add on columns to an executions table, containing information on the inventory (trade-by-trade) and later trades pertaining to the trade in question.
analysis:{[method;table;filter]
	table:?[table;(=),'flip(key filter;{$[type[x]=-11;enlist;::]x} each value filter);0b;()!()];
	newcols:0#enlist`TradedWith`TWprice`TWsize`originalID`origpx`origsz`TWpnl!(();0#0f;0#0f;();0#0f;0#0f;0#0f);
	newcols:inventory\[first newcols;0^prev table`position;table`side;table`px;table`sz;table`id] method;table,'newcols}

pnl:{[executions;mktrate;method]
	executions:executions lj select last bid,last ask by sym from mktrate;
	executions:update change:?[side=`buy;1;-1]*sz,id:i from executions;
	executions:update position:sums change by sym from executions;
	executions:`id xasc raze analysis[method;executions]each key select by sym from executions;
	executions:executions lj select TradedAgainst:TradedWith,TAprice:TWprice,TAsize:TWsize by id:TradedWith from select raze TradedWith,raze TWsize,raze TWprice from executions;
	executions:update allids:(TradedAgainst,'TradedWith),allpx:(TAprice,'TWprice),allszs:(TAsize,'TWsize)from executions;
	executions:update allpnl:(1 -1`buy=side)*(px*sum each allszs)-sum each allszs*allpx from executions;
	executions:update upnl:?[upnl within -.0001 .0001;0.;upnl]from update upnl:(1 -1`buy=side)*(px-?[position<0;ask;bid])*sz-sum each allszs from executions;
	executions:![executions;();0b;`bid`ask`Bidsize`change`Asksize`origsz`origpx`originalID`difference`TWprice`TWsize`TradedWith`TAprice`TAsize`TradedAgainst`allpx`allszs`allids];
	executions:update rpnl:.5*allpnl+TWpnl from executions;
	executions:update pnl:rpnl+upnl from executions}

\	
Sample usage.

execution table must be of form:
executions:([]time:`time$();sym:`symbol$();px:`float$();sz:`int$();side:`symbol$());
	
quotes table must be of form:
quotes:([]sym:`symbol$();bid:`float$();ask:`float$());

pnl[executions;quotes;`fifo]

or

pnl[executions;quotes;`lifo]


See file sample.q for further example usage.
