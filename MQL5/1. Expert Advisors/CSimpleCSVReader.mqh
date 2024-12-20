//+------------------------------------------------------------------+
//|                                             CSimpleCSVReader.mqh |
//|                                                      Sahil Bagdi |
//|                         https://www.mql5.com/en/users/sahilbagdi |
//+------------------------------------------------------------------+
#property copyright "Sahil Bagdi"
#property link      "https://www.mql5.com/en/users/sahilbagdi"

//+------------------------------------------------------------------+
//|  A simple CSV reader class in MQL5.                              |
//|  Assumes CSV file is located in MQL5/Files.                      |
//|  By default, uses ';' as the separator and treats first line as  |
//|  header. If no header, columns are accessed by index only.       |
//+------------------------------------------------------------------+

#include <Generic\HashMap.mqh>
#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayString.mqh>

class CSimpleCSVReader
  {
private:
   bool                  _hasHeader;
   string                _separator;
   CHashMap<string,uint> Columns;
   CArrayObj             Rows;          // Array of CArrayString*, each representing a data row

public:
                        CSimpleCSVReader()
                          {
                           _hasHeader = true;
                           _separator = ";";
                          }
                       ~CSimpleCSVReader()
                          {
                           Clear();
                          }

   void                 SetHasHeader(bool hasHeader) {_hasHeader = hasHeader;}
   void                 SetSeparator(string sep) {_separator = sep;}

   // Load: Reads the file, returns number of data rows.
   uint                 Load(string filename);

   // GetValue by name or index: returns specified cell value or errorVal if not found
   string               GetValueByName(uint rowNum, string colName, string errorVal="");
   string               GetValueByIndex(uint rowNum, uint colIndex, string errorVal="");

   // Returns the number of data rows (excluding header)
   uint                 RowCount() {return Rows.Total();}

   // Returns the number of columns. If no header, returns column count of first data row
   uint                 ColumnCount()
                         {
                          if(Columns.Count() > 0)
                            return Columns.Count();
                          // If no header, guess column count from first row if available
                          if(Rows.Total()>0)
                            {
                             CArrayString *r = Rows.At(0);
                             return (uint)r.Total();
                            }
                          return 0;
                         }

   // Get column name by index if header exists, otherwise return empty or errorVal
   string               GetColumnName(uint colIndex, string errorVal="")
                         {
                          if(Columns.Count()==0)
                            return errorVal;
                          // Extract keys and values from Columns
                          string keys[];
                          int vals[];
                          Columns.CopyTo(keys, vals);
                          if(colIndex < (uint)ArraySize(keys))
                            return keys[colIndex];
                          return errorVal;
                         }

private:
   void                 Clear()
                         {
                          for(int i=0; i<Rows.Total(); i++)
                            {
                             CArrayString *row = Rows.At(i);
                             if(row != NULL) delete row;
                            }
                          Rows.Clear();
                          Columns.Clear();
                         }
  };

//+------------------------------------------------------------------+
//| Implementation of Load() method                                  |
//+------------------------------------------------------------------+
uint CSimpleCSVReader::Load(string filename)
  {
   Clear(); // Start fresh

   int fileHandle = FileOpen(filename, FILE_READ|FILE_TXT);
   if(fileHandle == INVALID_HANDLE)
     {
      Print("CSVReader: Error opening file: ", filename, " err=", _LastError);
      return 0;
     }

   uint rowCount=0;

   // If hasHeader, read first line as header
   if(_hasHeader && !FileIsEnding(fileHandle))
     {
      string headerLine = FileReadString(fileHandle);
      if(headerLine != "")
        {
         string headerFields[];
         int colCount = StringSplit(headerLine, StringGetCharacter(_separator,0), headerFields);
         for(int i=0; i<colCount; i++)
           Columns.Add(headerFields[i], i);
        }
     }

   while(!FileIsEnding(fileHandle))
     {
      string line = FileReadString(fileHandle);
      if(line == "") continue; // skip empty lines

      string fields[];
      int fieldCount = StringSplit(line, StringGetCharacter(_separator,0), fields);
      if(fieldCount<1) continue; // no data?

      CArrayString *row = new CArrayString;
      for(int i=0; i<fieldCount; i++)
        row.Add(fields[i]);
      Rows.Add(row);
      rowCount++;
     }

   FileClose(fileHandle);
   return rowCount;
  }

//+------------------------------------------------------------------+
//| GetValueByIndex Method                                           |
//+------------------------------------------------------------------+
string CSimpleCSVReader::GetValueByIndex(uint rowNum, uint colIndex, string errorVal="")
  {
   if(rowNum >= Rows.Total())
     return errorVal;
   CArrayString *aRow = Rows.At(rowNum);
   if(aRow == NULL) return errorVal;
   if(colIndex >= (uint)aRow.Total())
     return errorVal;
   string val = aRow.At(colIndex);
   return val;
  }

//+------------------------------------------------------------------+
//| GetValueByName Method                                            |
//+------------------------------------------------------------------+
string CSimpleCSVReader::GetValueByName(uint rowNum, string colName, string errorVal="")
  {
   if(Columns.Count() == 0)
     {
      // No header, can't lookup by name
      return errorVal;
     }

   uint idx;
   bool found = Columns.TryGetValue(colName, idx);
   if(!found) return errorVal;

   return GetValueByIndex(rowNum, idx, errorVal);
  }

//+------------------------------------------------------------------+