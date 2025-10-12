
//+------------------------------------------------------------------+
//|                                                          WNN.mqh |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"

#include <Math\Stat\Normal.mqh>

//--- WNN (Wavelet Neural Network)

class WNN
  {
   protected:
      
      int m_deep;
      int m_deepth;
      string m_Symbol;
      double close[];
      matrix m_input;
      matrix m_pred_input;
      ENUM_TIMEFRAMES m_TF;
      matrix m_z_2;
      matrix m_a_2;
      matrix m_z_3;
      matrix m_yHat;
      double y_cor;
      double m_alpha;      
      
   public:
   
   matrix W_1;
   matrix W_2;
   matrix W_1_LSTM;

//--- WNN Constructor
//--- The constructor WNN initializes the neural network with parameters like the symbol, 
//--- timeframe, history depth, number of neurons, and learning rate (alpha).   
   WNN(string Symbol_, ENUM_TIMEFRAMES TimeFrame, int History_Depth, int Number_of_Neurons, double alpha);

//--- These functions implement the sigmoid activation function and its derivative, respectively.   
   double Sigmoid(double x);
   double Sigmoid_Prime(double x);

//--- This function returns the sign of a value, either +1 or -1.   
   int    Sgn( double Value);

//--- This function initializes a matrix with random values drawn from a normal distribution.   
   void   MatrixRandom(matrix& m);
   
//--- These functions apply the sigmoid function and its derivative to each element of a matrix, respectively.   
   matrix MatrixSigmoid(matrix& m);
   matrix MatrixSigmoidPrime(matrix& m);
   matrix Forward_Prop();
   double Cost();
   void   UpdateValues(int shift);
   void   Train(int shift);
   double Prediction();   
  };

WNN::WNN(string Symbol_,ENUM_TIMEFRAMES TimeFrame,int History_Depth,int Number_of_Neurons,double alpha)
  {
   m_Symbol = Symbol_;
   m_deepth = History_Depth;
   m_deep   = Number_of_Neurons;
   m_TF     = TimeFrame;
   m_alpha  = alpha; 
   
   matrix random_LSTM(1,m_deep);
   matrix random_W1(m_deepth,m_deep);
   matrix random_W2(m_deep,1);
    
   MatrixRandom(random_W1);
   MatrixRandom(random_W2);
   MatrixRandom(random_LSTM);
    
   W_1 = random_W1;
   W_2 = random_W2;
   W_1_LSTM = random_LSTM; 
    
   ArrayResize(close,m_deepth+5,0);
       
   m_yHat.Init(1,1);
   m_yHat[0][0] = 0;
   y_cor = -1;
   
  }

double WNN::Prediction(void)
  {
   matrix pred_z_2 = m_pred_input.MatMul(W_1) + W_1_LSTM;
   
   matrix pred_a_2 = MatrixSigmoid(pred_z_2);
   
   matrix pred_z_3 = pred_a_2.MatMul(W_2);
   
   matrix pred_yHat = MatrixSigmoid(pred_z_3);
   
   return m_yHat[0][0];
  }

void WNN::Train(int shift)
  {
   bool Train_condition = true;
   UpdateValues(shift);  
   while(Train_condition)
     {
      m_yHat = Forward_Prop();
      double J = Cost();
      
      if(J < m_alpha)
        {
         Train_condition = false;
        }
        
      matrix X_m_matrix = {{y_cor}};
      
      matrix cost = -1*(X_m_matrix - m_yHat);
      
      matrix z_3_prime = MatrixSigmoidPrime(m_z_3);
      
      matrix delta3 = cost.MatMul(z_3_prime);
      
      matrix dJdW2  = m_a_2.Transpose().MatMul(delta3);
      
      matrix z_2_prime = MatrixSigmoidPrime(m_z_2);
      
      matrix delta2 = delta3.MatMul(W_2.Transpose())*z_2_prime;
      
      matrix dJdW1 = m_input.Transpose().MatMul(delta2);
      
      W_1 = W_1 - dJdW1;
      W_2 = W_2 - dJdW2;
     }
   
   W_1_LSTM = m_input.MatMul(W_1);
   
  }

void WNN::UpdateValues(int shift)
  {
   for(int i=0 ; i<m_deepth+5 ; i++)
     {
      close[i] = iClose(m_Symbol,m_TF,i+shift);
     }
    
    m_input.Init(1,m_deepth);
    
    for(int i=0+1 ; i<m_deepth+1 ; i++)
      {
       m_input[0][i-1] = close[i];
      }

    m_pred_input.Init(1,m_deepth);
    
    for(int i=0 ; i<m_deepth ; i++)
      {
       m_input[0][i] = close[i];
      }
      
    y_cor = (Sgn(close[0]-close[1]) + 1)/2;            
  }

double WNN::Cost(void)
  {
   double J = .5*pow(y_cor - m_yHat[0][0],2);
   
   return J;    
  }

matrix WNN::Forward_Prop(void)
  {
   m_z_2 = m_input.MatMul(W_1) + W_1_LSTM;
   
   m_a_2 = MatrixSigmoid(m_z_2);
   
   m_z_3 = m_a_2.MatMul(W_2);
   
   m_yHat = MatrixSigmoid(m_z_3);
   
   return m_yHat; 
  }

//--- Sigmoid Function: σ(x)= 1 / 1 + e^(-x)​
//--- This function maps any input value to a range between 0 and 1, 
//--- which is useful for binary classification and as an activation function in neural networks.  
double WNN::Sigmoid(double x)
  {
   return 1/(1+MathExp(-x));
  }

//--- Sigmoid Derivative Function: σ′(x)=σ(x)⋅(1−σ(x))
//--- This derivative is used during backpropagation to compute gradients.
double WNN::Sigmoid_Prime(double x)
  {
   return MathExp(-x)/(pow(1+MathExp(-x),2));
  }


int WNN::Sgn(double Value)
  {
   int RES;
   
   if(Value > 0)
     {
      RES = 1;
     }
   else
     {
      RES = -1;
     }
   return RES;
  }

//--- This function initializes each element of the matrix m with random values drawn 
//--- from a normal distribution with mean 0 and standard deviation 1. 
void WNN::MatrixRandom(matrix &m)
  {
   int error;
   
   for(ulong r=0; r<m.Rows(); r++)
     {
      for(ulong c=0 ; c<m.Cols(); c++)
        {
         m[r][c] = MathRandomNormal(0,1,error);
        }
     }
  }
 
matrix WNN::MatrixSigmoid(matrix &m)
  {
   matrix m_2;
   m_2.Init(m.Rows(),m.Cols());   
   for(ulong r=0; r<m.Rows(); r++)
     {
      for(ulong c=0 ; c<m.Cols(); c++)
        {
         m_2[r][c] = Sigmoid(m[r][c]);
        }
     }
   return m_2;
  }

matrix WNN::MatrixSigmoidPrime(matrix &m)
 {
   matrix m_2;
   m_2.Init(m.Rows(),m.Cols());
   for(ulong r=0; r<m.Rows(); r++)
     {
      for(ulong c=0 ; c<m.Cols(); c++)
        {
         m_2[r][c] = Sigmoid_Prime(m[r][c]);
        }
     }
   return m_2;
 }