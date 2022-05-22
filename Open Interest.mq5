//+------------------------------------------------------------------+
//|                                                Open Interest.mq5 |
//|                                                           Volder |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Volder"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   6

#property indicator_label1 "Total"
#property indicator_label2 "%Index"
#property indicator_label3 "Ld-contracts/Near-contracts"
#property indicator_label4 "Ld-contracts/Near-contracts%"
#property indicator_label5 "Ld-contracts/All-contracts"
#property indicator_label6 "Ld-contracts/All-contracts%"

#property indicator_color1 clrBlack
#property indicator_color2 clrDarkSlateGray
#property indicator_color3 clrGreen
#property indicator_color4 clrForestGreen
#property indicator_color5 clrDarkBlue
#property indicator_color6 clrDarkSlateBlue


#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 2
#property indicator_width6 2

#property script_show_inputs

double OIBuffer[];
double OIPercentBuffer[];
double LDNearBuffer[];
double LDNearPersBuffer[];
double LDALLBuffer[];
double LDALLPersBuffer[];

#define SOME_ENUM(DO) \
   DO(current) \
   DO(aluminum_mw_us_transaction_premium_platts_25mt_comex) \
   DO(australian_dollar_cme) \
   DO(bitcoin_cme) \
   DO(bitcoin_micro_cme) \
   DO(british_pound_cme) \
   DO(canadian_dollar_cme) \
   DO(cash_settled_butter_cme) \
   DO(cash_settled_cheese_cme) \
   DO(chicago_srw_wheat_cbot) \
   DO(class_iii_milk_cme) \
   DO(cocoa_nycc_ice) \
   DO(coffee_c_nycc_ice) \
   DO(copper_comex) \
   DO(corn_cbot) \
   DO(e_mini_nasdaq_100_cme) \
   DO(e_mini_russell_2000_index_cme) \
   DO(e_mini_sp_midcap_400_cme) \
   DO(e_mini_sp500_cme) \
   DO(euro_fx_cme) \
   DO(eurodollar_cme) \
   DO(feeder_cattle_cme) \
   DO(gold_comex) \
   DO(henry_hub_natural_gas_nymex) \
   DO(japanese_yen_cme) \
   DO(kc_hrw_wheat_cbot) \
   DO(lean_hog_cme) \
   DO(live_cattle_cme) \
   DO(new_zealand_dollar_cme) \
   DO(palladium_nymex) \
   DO(platinum_nymex) \
   DO(rough_rice_cbot) \
   DO(russian_ruble_cme) \
   DO(silver_comex) \
   DO(soybean_cbot) \
   DO(soybean_meal_cbot) \
   DO(soybean_oil_cbot) \
   DO(sugar_no_11_nycc_ice) \
   DO(swiss_franc_cme) \
   DO(ultra_10_year_us_treasury_note_cbot) \
   DO(ultra_us_treasury_bond_cbot) \
   DO(us_midwest_domestic_hot_rolled_coil_steel_cru_index_comex) \
   DO(us_treasury_bond_cbot) \
   DO(wti_crude_oil_nymex) \
   DO(two_year_t_note_cbot) \
   DO(five_year_t_note_cbot) \
   DO(ten_year_t_note_cbot) \
   DO(thirty_day_federal_funds_cbot) \

#define MAKE_ENUM(VAR) VAR,
enum Instruments {
    SOME_ENUM(MAKE_ENUM)
};

#define MAKE_STRINGS(VAR) #VAR,
string InstrumentsNames[] = {
    SOME_ENUM(MAKE_STRINGS)
};

struct exp_coeffs {
   string mounth_name;
   double coef;
};

exp_coeffs array_coeffs_wheat[] = {
   {"MAR", 1.0/62},
   {"MAY", 1.0/43},
   {"JUL", 1.0/42},
   {"SEP", 1.0/43},
   {"DEC", 1.0/63}
};

exp_coeffs array_coeffs_gold[] = {
   {"JAN", 1.0/20},
   {"FEB", 1.0/19},
   {"MAR", 1.0/22},
   {"APR", 1.0/22},
   {"MAY", 1.0/20},
   {"JUN", 1.0/22},
   {"JUL", 1.0/22},
   {"AUG", 1.0/22},
   {"SEP", 1.0/20},
   {"OCT", 1.0/22},
   {"NOV", 1.0/20},
   {"DEC", 1.0/21}
   
};

exp_coeffs array_coeffs_current[12];

//--- input parameters
input Instruments selecting = current;             //Отобразить на графике
input ENUM_DRAW_TYPE styling1 = DRAW_HISTOGRAM;    //Open Interest
input ENUM_DRAW_TYPE styling2 = DRAW_NONE;         //%Interest
input ENUM_DRAW_TYPE styling3 = DRAW_NONE;         //Ld-contracts/Near-contracts
input ENUM_DRAW_TYPE styling4 = DRAW_NONE;         //Ld-contracts/Near-contracts%
input ENUM_DRAW_TYPE styling5 = DRAW_NONE;         //Ld-contracts/All-contracts
input ENUM_DRAW_TYPE styling6 = DRAW_NONE;         //Ld-contracts/All-contracts%

input int period = 26;
int p = period*5;


int file;
string filename;
string current_symbol;
string current_instr;


void my_copy_array(exp_coeffs& dest[], exp_coeffs& src[])
{
   for(int i = 0; i < ArraySize(src); ++i) {
      dest[i].mounth_name = src[i].mounth_name;
      dest[i].coef = src[i].coef;
   }

}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Запуск индикатора Open Interest");

   SetIndexBuffer(0, OIBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, OIPercentBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LDNearBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LDNearPersBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, LDALLBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, LDALLPersBuffer, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, styling1);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, styling2);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, styling3);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, styling4);
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, styling5);
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, styling6);
   
   PlotIndexSetDouble (0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble (2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble (4, PLOT_EMPTY_VALUE, 0.0);


   if(selecting != current) {
      current_instr = InstrumentsNames[selecting];
   } else {
      current_symbol = Symbol();
      if(current_symbol == "EURUSD") current_instr = InstrumentsNames[euro_fx_cme];
      else if(current_symbol == "GBPUSD") current_instr = InstrumentsNames[british_pound_cme];
      else if(current_symbol == "AUDUSD") current_instr = InstrumentsNames[australian_dollar_cme];
      else if(current_symbol == "NZDUSD") current_instr = InstrumentsNames[new_zealand_dollar_cme];
      else if(current_symbol == "USDJPY") current_instr = InstrumentsNames[japanese_yen_cme];
      else if(current_symbol == "USDCAD") current_instr = InstrumentsNames[canadian_dollar_cme];
      else if(current_symbol == "USDCHF") current_instr = InstrumentsNames[swiss_franc_cme];
      else if(current_symbol == "USDRUB") current_instr = InstrumentsNames[russian_ruble_cme];
      else if(current_symbol == "SILVER") current_instr = InstrumentsNames[silver_comex];
      else if(current_symbol == "GOLD") {
         current_instr = InstrumentsNames[gold_comex];
         my_copy_array(array_coeffs_current, array_coeffs_gold);
      }
      else if(StringFind(current_symbol, "Wheat", 0) >=0) {
         current_instr = InstrumentsNames[chicago_srw_wheat_cbot];
         my_copy_array(array_coeffs_current, array_coeffs_wheat);
      }
      else if (current_symbol == "BTCUSD") current_instr = InstrumentsNames[bitcoin_cme];
      else if (current_symbol == "NQ") current_instr = InstrumentsNames[e_mini_nasdaq_100_cme];
      else if (current_symbol == "TF") current_instr = InstrumentsNames[e_mini_russell_2000_index_cme];
      else if (current_symbol == "ES") current_instr = InstrumentsNames[e_mini_sp500_cme];
      else if (current_symbol == "COFFEE") current_instr = InstrumentsNames[coffee_c_nycc_ice];
      else if (StringFind(current_symbol, "Corn", 0) >=0) {
         current_instr = InstrumentsNames[corn_cbot];
         my_copy_array(array_coeffs_current, array_coeffs_wheat);
      }
      else if (current_symbol == "COCOA") current_instr = InstrumentsNames[cocoa_nycc_ice];
      else if (current_symbol == "SOYBEAN") current_instr = InstrumentsNames[soybean_cbot];
      else if (current_symbol == "SUGAR") current_instr = InstrumentsNames[sugar_no_11_nycc_ice];
      else if (current_symbol == "CL") current_instr = InstrumentsNames[wti_crude_oil_nymex];
      else if (current_symbol == "WTI") current_instr = InstrumentsNames[wti_crude_oil_nymex];
      else if (StringFind(current_symbol, "GAS", 0) >=0) current_instr = InstrumentsNames[henry_hub_natural_gas_nymex];
      else if (current_symbol == "HG") current_instr = InstrumentsNames[copper_comex];
      else if (current_symbol == "PALLADIUM") current_instr = InstrumentsNames[palladium_nymex];
      else if (current_symbol == "PLATINUM") current_instr = InstrumentsNames[platinum_nymex];
      else current_instr = InstrumentsNames[euro_fx_cme];
   }
   
   IndicatorSetString(INDICATOR_SHORTNAME, "Open Interest: " + current_instr);
   file = FileOpen("OpenInterest\\" + current_instr + ".txt", FILE_READ|FILE_SHARE_READ|FILE_TXT|FILE_ANSI, '\t');
   
   if(file == INVALID_HANDLE) Print("Файл " + current_instr + ".txt не окрылся");
   else Print("Файл " + current_instr + ".txt успешно окрыт");
   
   
   return(INIT_SUCCEEDED);
}

double define_coef(string mounth_name)
{
   for(int i = 0; i < ArraySize(array_coeffs_current); ++i)
      if(StringFind(mounth_name, array_coeffs_current[i].mounth_name, 0) >=0) 
         return array_coeffs_current[i].coef;
   return -1;
}

void extract_filestring(int fn, string &string_array[] )
{
   string filestring = FileReadString(fn);
   StringSplit(filestring, '\t', string_array);
}

void wheat_handler(const int rates_total, const datetime &time[])
{
   string string_array[];
   double coef;
   string last_mn;
   string curr_mn;
   string started;
   int start = 0;
   
   FileSeek(file, 0, SEEK_SET);
   extract_filestring(file, string_array);
  
   last_mn = string_array[4];
   while(true) {
      extract_filestring(file, string_array);
      curr_mn = string_array[4];
      if(curr_mn != last_mn)
         break;
      last_mn = curr_mn;
   }
      
   for(int i = start; i < rates_total; ++i) {
      started = TimeToString(time[i], TIME_DATE);
      if(started == string_array[0]) {
         start = i;
         break;
      }
   }
      
   coef = define_coef(curr_mn);
   double decr_coef = 1;
   double incr_coef = 0;
      
   double near_contr, ld_contr;
   for(int i = start; i < rates_total-1; ++i) {
      last_mn = curr_mn;
      started = TimeToString(time[i], TIME_DATE);
      while(started != string_array[0]) {
         if(started > string_array[0]) {
            extract_filestring(file, string_array);
         }
         else {
            ++i;
            started = TimeToString(time[i], TIME_DATE);
         }
      }
      
      if(started == string_array[0]) {
         near_contr = 
            (decr_coef*StringToDouble(string_array[5])) +
            (incr_coef*StringToDouble(string_array[7]));
         ld_contr = 1 * (
            (decr_coef*StringToDouble(string_array[7])) +
            (incr_coef*StringToDouble(string_array[9]))
         );
         LDNearBuffer[i] = ld_contr/near_contr;
         LDALLBuffer[i] = ld_contr/StringToDouble(string_array[3]);
            
         decr_coef -= coef;
         incr_coef += coef;
      }
         
      if(FileIsEnding(file))
         break;
      extract_filestring(file, string_array);
      curr_mn = string_array[4];
      if(curr_mn != last_mn) {
         decr_coef = 1;
         incr_coef = 0;
         coef = define_coef(curr_mn);
      }
   }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   string string_array[];
   string started;
   int start = 0;
   string that_time;
   string instr_time;
   
   if(prev_calculated != 0)
      return(rates_total);
      
   ArrayInitialize(OIBuffer, 0);
   ArrayInitialize(OIPercentBuffer, 0);
   ArrayInitialize(LDNearBuffer, 0);
   ArrayInitialize(LDNearPersBuffer, 0);
   ArrayInitialize(LDALLBuffer, 0);
   ArrayInitialize(LDALLPersBuffer, 0);
      
   FileSeek(file, 0, SEEK_SET);
   extract_filestring(file, string_array);
      
   for(int i = 0; i < rates_total; ++i) {
      started = TimeToString(time[i], TIME_DATE);
      if(started == string_array[0]) {
         start = i;
         break;
      }
   }
        
   for(int i = start; i < rates_total; ++i) {
      that_time = TimeToString(time[i], TIME_DATE);
      FileSeek(file, 0, SEEK_SET);
     
      while(!FileIsEnding(file)) {
         extract_filestring(file, string_array);
         instr_time = string_array[0];
         if(that_time == instr_time) {
            OIBuffer[i] = StringToDouble(string_array[3]);
            break;
         }
      }
      if(OIBuffer[i] == 0)
         OIBuffer[i] = OIBuffer[i-1];
   }
   
   for(int j = start + p - 1; j < rates_total; ++j)
      OIPercentBuffer[j] = 100*(
         (OIBuffer[j] - OIBuffer[ArrayMinimum(OIBuffer, j - p + 1, p)])/
         (OIBuffer[ArrayMaximum(OIBuffer, j - p + 1, p)] - OIBuffer[ArrayMinimum(OIBuffer, j - p + 1, p)])
      );   
   
   
   wheat_handler(rates_total, time);
   
   for(int j = start + p - 1; j < rates_total; ++j) {
      LDNearPersBuffer[j] = 100*(
         (LDNearBuffer[j] - LDNearBuffer[ArrayMinimum(LDNearBuffer, j - p + 1, p)])/
         (LDNearBuffer[ArrayMaximum(LDNearBuffer, j - p + 1, p)] - LDNearBuffer[ArrayMinimum(LDNearBuffer, j - p + 1, p)])
      );
      LDALLPersBuffer[j] = 100*(
         (LDALLBuffer[j] - LDALLBuffer[ArrayMinimum(LDALLBuffer, j - p + 1, p)])/
         (LDALLBuffer[ArrayMaximum(LDALLBuffer, j - p + 1, p)] - LDALLBuffer[ArrayMinimum(LDALLBuffer, j - p + 1, p)])
      );
   }
      
   return(rates_total);
}
//+------------------------------------------------------------------+
