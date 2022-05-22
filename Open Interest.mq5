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

//--- input parameters


double OIBuffer[];
double OIPercentBuffer[];
double LDNearBuffer[];
double LDNearPersBuffer[];
double LDALLBuffer[];
double LDALLPersBuffer[];

enum Instruments
{
   current = 0,                                                //Текущий инструмент
   aluminum_mw_us_transaction_premium_platts_25mt_comex,      //Aluminum MW US COMEX
   australian_dollar_cme,                                      //Australian Dollar CME
   bitcoin_cme,                                                //Bitcoin CME
   bitcoin_micro_cme,                                          //Bitcoin Micro CME
   british_pound_cme,                                          //British Pound CME
   canadian_dollar_cme,                                        //Canadian Dollar CME
   cash_settled_butter_cme,                                    //Cash-settled Butter CME
   cash_settled_cheese_cme,                                    //Cash-settled Cheese CME
   chicago_srw_wheat_cbot,                                     //Chicago SRW Wheat CBOT
   class_iii_milk_cme,                                         //Class III Milk CME
   cocoa_nycc_ice,                                             //Cocoa NYCC ICE
   coffee_c_nycc_ice,                                          //Coffee 'C' NYCC ICE
   copper_comex,                                               //Copper COMEX
   corn_cbot,                                                  //Corn CBOT
   e_mini_nasdaq_100_cme,                                      //E-mini Nasdaq-100 CME
   e_mini_russell_2000_index_cme,                              //E-mini Russell 2000 index CME
   e_mini_sp_midcap_400_cme,                                  //E-mini S&P Midcap 400 CME
   e_mini_sp500_cme,                                          //E-mini S&P 500 CME
   euro_fx_cme,                                                //Euro FX CME
   eurodollar_cme,                                             //Eurodollar CME
   feeder_cattle_cme,                                          //Feeder cattle CME
   gold_comex,                                                 //Gold COMEX
   henry_hub_natural_gas_nymex,                                //Henry hubnatural gas NYMEX
   japanese_yen_cme,                                           //Japanese Yen CME
   kc_hrw_wheat_cbot,                                          //KC HRW Wheat CBOT
   lean_hog_cme,                                               //Lean hog CME
   live_cattle_cme,                                            //Live Cattle CME
   new_zealand_dollar_cme,                                     //New Zealand Dollar CME
   palladium_nymex,                                            //Palladium NYMEX
   platinum_nymex,                                             //Platinum NYMEX
   rough_rice_cbot,                                            //Rough rice CBOT
   russian_ruble_cme,                                          //Russian ruble CME
   sp500_cme,                                                 //S&P 500 CME
   silver_comex,                                               //Silver COMEX
   soybean_cbot,                                               //Soybean CBOT
   soybean_meal_cbot,                                          //Soybean meal CBOT
   soybean_oil_cbot,                                           //Soybean oil CBOT
   sugar_no_11_nycc_ice,                                       //Sugar no 11 NYCC ICE
   swiss_franc_cme,                                            //Swiss Franc CME
   ultra_10_year_us_treasury_note_cbot,                        //Ultra 10-year US Treasury Note CBOT,
   ultra_us_treasury_bond_cbot,                                //Ultra US Treasury Bond CBOT
   us_midwest_domestic_hot_rolled_coil_steel_cru_index_comex,//US Midwest domestic hot-rolled coil steel (CRU) index COMEX
   us_treasury_bond_cbot,                                      //US Treasury Bond CBOT
   wti_crude_oil_nymex,                                        //WTI Crude Oil NYMEX
   two_year_t_note_cbot,                                       //2-Year T-note CBOT
   five_year_t_note_cbot,                                      //5-Year T-note CBOT
   ten_year_t_note_cbot,                                       //10-Year T-note CBOT
   thirty_day_federal_funds_cbot                               //30 day Federal Funds CBOT
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


   current_symbol = Symbol();

   if(current_symbol == "EURUSD") current_instr = "euro_fx_cme";
   else if(current_symbol == "GBPUSD") current_instr = "british_pound_cme";
   else if(current_symbol == "AUDUSD") current_instr = "australian_dollar_cme";
   else if(current_symbol == "NZDUSD") current_instr = "new_zealand_dollar_cme";
   else if(current_symbol == "USDJPY") current_instr = "japanese_yen_cme";
   else if(current_symbol == "USDCAD") current_instr = "canadian_dollar_cme";
   else if(current_symbol == "USDCHF") current_instr = "swiss_franc_cme";
   else if(current_symbol == "USDRUB") current_instr = "russian_ruble_cme";
   else if(current_symbol == "SILVER") current_instr = "silver_comex";
   else if(current_symbol == "GOLD") {
      current_instr = "gold_comex";
      my_copy_array(array_coeffs_current, array_coeffs_gold);
   }
   else if(StringFind(current_symbol, "Wheat", 0) >=0) {
      current_instr = "chicago_srw_wheat_cbot";
      my_copy_array(array_coeffs_current, array_coeffs_wheat);
   }
   else if (current_symbol == "BTCUSD") current_instr = "bitcoin_cme";
   else if (current_symbol == "NQ") current_instr = "e-mini_nasdaq-100_cme";
   else if (current_symbol == "TF") current_instr = "e-mini_russell_2000_index_cme";
   else if (current_symbol == "ES") current_instr = "e-mini_s&p500_cme";
   else if (current_symbol == "COFFEE") current_instr = "coffee_c_nycc_ice";
   else if (StringFind(current_symbol, "Corn", 0) >=0) {
      current_instr = "corn_cbot";
      my_copy_array(array_coeffs_current, array_coeffs_wheat);
   }
   else if (current_symbol == "COCOA") current_instr = "cocoa_nycc_ice";
   else if (current_symbol == "SOYBEAN") current_instr = "soybean_cbot";
   else if (current_symbol == "SUGAR") current_instr = "sugar_no_11_nycc_ice";
   else if (current_symbol == "CL") current_instr = "wti_crude_oil_nymex";
   else if (current_symbol == "WTI") current_instr = "wti_crude_oil_nymex";
   else if (StringFind(current_symbol, "GAS", 0) >=0) current_instr = "henry_hub_natural_gas_nymex";
   else if (current_symbol == "HG") current_instr = "copper_comex";
   else if (current_symbol == "PALLADIUM") current_instr = "palladium_nymex";
   else if (current_symbol == "PLATINUM") current_instr = "platinum_nymex";
   else current_instr = "euro_fx_cme";
   
   
   switch(selecting) {
      case current:
         filename = current_instr;
         break;
      case aluminum_mw_us_transaction_premium_platts_25mt_comex:
         filename = "aluminum_mw_us_transaction_premium_platts(25mt)_comex";
         break;
      case australian_dollar_cme:
         filename = "australian_dollar_cme";
         break;
      case british_pound_cme:
         filename = "british_pound_cme";
         break;
      case canadian_dollar_cme:
         filename = "canadian_dollar_cme";
         break;
      case cash_settled_butter_cme:
         filename = "cash-settled_butter_cme";
         break;
      case cash_settled_cheese_cme:
         filename = "cash-settled_cheese_cme";
         break;
      case class_iii_milk_cme:
         filename = "class_iii_milk_cme";
         break;
      case cocoa_nycc_ice:
         filename = "cocoa_nycc_ice";
         break;
      case coffee_c_nycc_ice:
         filename = "coffee_c_nycc_ice";
         break;
      case copper_comex:
         filename = "copper_comex";
         break;
      case corn_cbot:
         filename = "corn_cbot";
         break;
      case e_mini_nasdaq_100_cme:
         filename = "e-mini_nasdaq-100_cme";
         break;
      case e_mini_russell_2000_index_cme:
         filename = "e-mini_russell_2000_index_cme";
         break;
      case bitcoin_cme:
         filename = "bitcoin_cme";
         break;
      case bitcoin_micro_cme:
         filename = "bitcoin_micro_cme";
         break;
      case chicago_srw_wheat_cbot:
         filename = "chicago_srw_wheat_cbot";
         break;
      case e_mini_sp_midcap_400_cme:
         filename = "e-mini_s&p_midcap_400_cme";
         break;
      case e_mini_sp500_cme:
         filename = "e-mini_s&p500_cme";
         break;
      case euro_fx_cme:
         filename = "euro_fx_cme";
         break;
      case eurodollar_cme:
         filename = "eurodollar_cme";
         break;
      case feeder_cattle_cme:
         filename = "feeder_cattle_cme";
         break;
      case gold_comex:
         filename = "gold_comex";
         break;
      case henry_hub_natural_gas_nymex:
         filename = "henry_hub_natural_gas_nymex";
         break;
      case japanese_yen_cme:
         filename = "japanese_yen_cme";
         break;
      case kc_hrw_wheat_cbot:
         filename = "kc_hrw_wheat_cbot";
         break;
      case lean_hog_cme:
         filename = "lean_hog_cme";
         break;
      case live_cattle_cme:
         filename = "live_cattle_cme";
         break;
      case new_zealand_dollar_cme:
         filename = "new_zealand_dollar_cme";
         break;
      case palladium_nymex:
         filename = "palladium_nymex";
         break;
      case platinum_nymex:
         filename = "platinum_nymex";
         break;
      case rough_rice_cbot:
         filename = "rough_rice_cbot";
         break;
      case russian_ruble_cme:
         filename = "russian_ruble_cme";
         break;
      case sp500_cme:
         filename = "s&p500_cme";
         break;
      case silver_comex:
         filename = "silver_comex";
         break;
      case soybean_cbot:
         filename = "soybean_cbot";
         break;
      case soybean_meal_cbot:
         filename = "soybean_meal_cbot";
         break;
      case soybean_oil_cbot:
         filename = "soybean_oil_cbot";
         break;
      case sugar_no_11_nycc_ice:
         filename = "sugar_no_11_nycc_ice";
         break;
      case swiss_franc_cme:
         filename = "swiss_franc_cme";
         break;
      case ultra_10_year_us_treasury_note_cbot:
         filename = "ultra_10-year_us_treasury_note_cbot";
         break;
      case ultra_us_treasury_bond_cbot:
         filename = "ultra_us_treasury_bond_cbot";
         break;
      case us_midwest_domestic_hot_rolled_coil_steel_cru_index_comex:
         filename = "us_midwest_domestic_hot-rolled_coil_steel_(cru)_index_comex";
         break;
      case us_treasury_bond_cbot:
         filename = "us_treasury_bond_cbot";
         break;
      case wti_crude_oil_nymex:
         filename = "wti_crude_oil_nymex";
         break;
      case two_year_t_note_cbot:
         filename = "2_year_t-note_cbot";
         break;
      case five_year_t_note_cbot:
         filename = "5_year_t-note_cbot";
         break;
      case ten_year_t_note_cbot:
         filename = "10_year_t-note_cbot";
         break;
      case thirty_day_federal_funds_cbot:
         filename = "30_day_federal_funds_cbot";
         break;
   }
   
   IndicatorSetString(INDICATOR_SHORTNAME, "Open Interest: " + filename);
   file = FileOpen("OpenInterest\\" + filename + ".txt", FILE_READ|FILE_SHARE_READ|FILE_TXT|FILE_ANSI, '\t');
   
   if(file == INVALID_HANDLE) Print("Файл " + filename + ".txt не окрылся");
   else Print("Файл " + filename + ".txt успешно окрыт");
   
   
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
   /*
   string filestring;
   string started;
   int start = 0;
   string that_time;
   string instr_time;
   
   
   
   if(prev_calculated == 0) {
      FileSeek(file, 0, SEEK_SET);
      ArrayInitialize(OIBuffer, 0);
      ArrayInitialize(OIPercentBuffer, 0);
      string string_array[];
      
      filestring = FileReadString(file);
      StringSplit(filestring, '\t', string_array);
      
      for(int i = 0; i < rates_total; ++i) {
         started = TimeToString(time[i], TIME_DATE);
         if(started == string_array[0]) {
            start = i;
            break;
         }
      }
      
   }
   else start = rates_total - 1;
   
   for(int i = start; i < rates_total; ++i) {
      that_time = TimeToString(time[i], TIME_DATE);
      FileSeek(file, 0, SEEK_SET);
     
      while(!FileIsEnding(file)) {
         string string_array[];
         filestring = FileReadString(file);
         StringSplit(filestring, '\t', string_array);
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
*/   

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
