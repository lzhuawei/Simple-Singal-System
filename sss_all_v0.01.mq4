﻿//+------------------------------------------------------------------+
//|                                                  sar-ea01.mq4 |
//|                      Copyright ?2005, MetaQuotes Software Corp.  |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#define MAGICMA  10001
extern int TakeProfit = 2000;      //止盈，此平台外汇为500点为50点，黄金500点表示5美金
extern int stoploss=300;          //从挂单价位多少点止损  黄金500点表示5美金    
extern int TrailingStop=400;      //移动止损
//extern double Lots=0.01;         //订单量
int onetime;                //开单成功记录时间，加上延迟秒数关闭未成交挂单
input double Lots          =0.01;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
double f_low,f_high;//存储前低价格和前高价格，用于判断做多时止损和做空时止损的价格

int start()
{
if(CalculateCurrentOrders(Symbol())==0 && bs_signal()!=0)opentrade();
//CalculateCurrentOrders(Symbol())==0订单数量可以设置<=？符合条件可以多次开仓
//只有有一单，即不再执行开单函数
//<=?可能出现的情况，订单数没有达到要求，在符合时间间隔的条件下，再执行开仓函数
//可能在信号满足的情况下，即开多单又开空单，对冲单不符合要求！
if(CalculateCurrentOrders(Symbol())!=0)modifytrade();//

Print("LotsOptimized()函数输入出值=" ,LotsOptimized());
Print("CalculateCurrentOrders函数输出值=",CalculateCurrentOrders(Symbol()));
Print("bs_signal()信号值=",bs_signal());
//Print("时间=",TimeToStr(onetime));
Print("当前时间：",TimeToStr(TimeCurrent()),"  转换时间加K线周期后：",TimeToStr(closetime()));//


 return(0);
}
//+自定义函数功能调用+
//+统计所有订单当中符合要求参数symbol的订单数并返回统计结果+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
   if(buys>0) return(buys);
   else       return(-sells);
  }
  //+以上判断是否已经开仓+
  
  //sar条件自定义函数
int bs_signal()
  {
  int isopen;
  int i,low = 0,hight = 0;
 int py=PERIOD_H1,pz=0,p=0; double sar0=iSAR(NULL,pz,0.04,0.5,0);//当前时间周期K线的SAR值
 double sar[200],sar_hightemp[50][50],sar_lowtemp[50][50];

 double sar_y_1st=iSAR(NULL,py,0.04,0.5,1);//第一根K线的SAR值
 double sar_y_0=iSAR(NULL,py,0.04,0.5,0);  //当前正在tickr的K线的SAR值
for(i=1;i<200;i++)
  {
    sar[i]=iSAR(NULL,0,0.04,0.5,i);//将从当前K线的SAR分别计算存入数组;
      if(Close[i]<sar[i]&&Close[i-1]>sar[i-1])
      {
         sar_lowtemp[low][0]=sar[i-1];//金叉条件，找最低值存入数组
         sar_lowtemp[low][1] = i - 1;//金叉条件，找最低值存入数组
         low++;
      }
      if(Close[i]>sar[i]&&Close[i-1]<sar[i-1])
      {
         sar_hightemp[hight][0]=sar[i-1];//死叉条件，找最高值存入数组
         sar_hightemp[hight][1] = i - 1;
         hight++;
      }
 }
   f_low=sar_lowtemp[0][0];
    f_high=sar_hightemp[0][0];
 if(Close[2]<sar[2] &&Close[1]>sar[1] && Close[0]>sar0)isopen=1; //&&Close[0]>sar_y_0&&(Close[0]-f_low)/Point<=100
 if(Close[2]>sar[2] &&Close[1]<sar[1] && Close[0]<sar0)isopen=2;//&&Close[1]<sar_y_0&&(f_high-Close[0])/Point<=100
 return(isopen);
}
 //执行开仓函数
int opentrade()
{
  bool opentime=false;
if(TimeCurrent()>onetime+Period()*60)onetime=1; 
//变量存放上一单开仓时间值，加上至少一个K线周期之后，才能开启下单状态，
//避免同一K线可能由于手动或者止损止盈的原因，继续开仓而导致的失误
 //开单成功后onetime默认为0的变量变成为开单时间存储为全局变量，时间超过至少一根K线之后，再次赋值为1来满足下单条件
if(Hour()>=0&&Hour()<=24){opentime=true;}//时间限制在北京时间8点到凌晨2点

int ticket_buy,ticket_sell;
   if(Bars<100)Print("bars less than 100");
   if(TakeProfit<10)
      {
      Print("TakeProfit less than 10");
      return(0);
      }
   if(bs_signal()==1 && onetime==1)
     {
      if(AccountFreeMargin()<(1*Lots))
        {
         Print("We have no money. Free Margin = ",AccountFreeMargin());
         return(0);
        }
        {
            ticket_buy=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,f_low-stoploss*Point,Ask+TakeProfit*Point,"SAR",MAGICMA,0,Green);//
            if(ticket_buy>0){Alert(Symbol(),"--买单开仓成功");onetime=Time[0];}
            else Print("Error opening BUY order : ",GetLastError());
         return(0);
        }
     }
  if(bs_signal()==2&& onetime==1)
     {
      if(AccountFreeMargin()<(1*Lots))
        {
         Print("We have no money. Free Margin = ",AccountFreeMargin());
         return(0);
        }
           {
            ticket_sell=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,f_high+stoploss*Point,Bid-TakeProfit*Point,"SAR",MAGICMA,0,Red);//
            if(ticket_sell>0){Alert(Symbol(),"--空单开仓成功");onetime=Time[0];}
            else Print("Error opening BUY order : ",GetLastError());
         return(0);
        }
     }
return(0);
}  


void closetrade()
{
   int closebuy,closesell;
   for(int cnt=0;cnt<OrdersTotal();cnt++)
     {
      bool f=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
     
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA) // check for symbol
        {
         if(OrderType()==OP_BUY) // long position is opened
            { closebuy =OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
             if(closebuy>0)Alert(Symbol(),"--多单平仓成功");
             else Print("Error close BUY order : ",GetLastError());}
         else  //OrderType()==OP_SELL
           {  closesell=OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
             if(closebuy>0)Alert(Symbol(),"--空单平仓成功");
             else Print("Error close SELL order : ",GetLastError());}
        }
     }
}
void modifytrade()
{
    for(int cnt=0;cnt<OrdersTotal();cnt++)
     {
      bool f=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA) // check for symbol
        {
          if(TrailingStop>0)
              {
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                      //if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green))
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green))
                        Print("OrderModify error ",GetLastError());
                    }
                 }
              }
}
        if(OrderType()==OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA) // check for symbol
        {      
          if(TrailingStop>0)
              {
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     //--- modify order and exit
                     //if(!OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green))
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red))
                        Print("OrderModify error ",GetLastError());
                    }
                 }
              }
}
}
}
int closetime() //历史订单当中最新关闭的订单时间,防止信号有效情况下反复下单
{
  int time;
   for(int cnt=OrdersHistoryTotal()-1;cnt>0;cnt--)
     {
      bool f=OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
      time=OrderCloseTime();//+Period()*60;
      return(time);
      }
}
int opentime() //历史订单当中最新关闭的订单时间,防止信号有效情况下反复下单
{
   datetime ktime=iTime(NULL,0,1);
   for(int cnt=0;cnt<OrdersTotal();cnt++)
     {
      bool f=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
      int time=OrderOpenTime();//+Period()*60;
      return(time);
      }
}



//检查下单量
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
}
