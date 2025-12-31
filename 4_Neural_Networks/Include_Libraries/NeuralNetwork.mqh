
//+------------------------------------------------------------------+
//|                                            NeuralNetwork.mqh.mqh |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"

#include <Math\Stat\Normal.mqh>

class NeuralNetwork
  {
private:
   int               m_maxiters;
   double            m_beta_1;
   double            m_beta_2;
   bool              m_verbose;
   double            m_LearningRate;
   int               m_deep;
   int               m_depth;
   matrix            m_input;
   matrix            m_pred_input;
   matrix            m_z_2;
   matrix            m_a_2;
   matrix            m_z_3;
   matrix            m_yHat;
   matrix            z_3_prime;
   matrix            z_2_prime;
   matrix            delta2;
   matrix            delta3;
   matrix            dJdW1;
   matrix            dJdW2;
   matrix            y_cor;
   double            m_alpha;
   int               m_outDim;
   matrix            Forward_Prop(matrix &Input);
   double            Cost(matrix &Input, matrix &y_cor);
   double            Sigmoid(double x);
   double            Sigmoid_Prime(double x);
   void              MatrixRandom(matrix &m);
   matrix            MatrixSigmoidPrime(matrix &m);
   matrix            MatrixSigmoid(matrix &m);
   void              ComputeDerivatives(matrix &Input, matrix &y_);

public:

   matrix            W_1;
   matrix            W_2;

                     NeuralNetwork(int in_DimensionRow,int in_DimensionCol,int Number_of_Neurons,int out_Dimension,double alpha,double LearningRate,bool Verbose,double beta_1, double beta_2,int max_iterations);
   void              Train(matrix& Input,matrix &correct_Val);
   int               Sgn(double Value);
   matrix            Prediction(matrix& Input);
   void              ResetWeights();
   bool              WriteWeights();
   bool              LoadWeights();

   // A_nxm X B_mxa = X_nxa
  };

bool NeuralNetwork::LoadWeights(void)
  {

   int handle = FileOpen("Weights_1.txt",FILE_READ,",",FILE_TXT);

   return true;

  }

bool NeuralNetwork::WriteWeights(void)
  {

   string InpName = "Weights_1.txt";

   int handle_w1=FileOpen(InpName,FILE_READ|FILE_WRITE|FILE_CSV);

   InpName = "Weights_2.txt";

   int handle_w2=FileOpen(InpName,FILE_READ|FILE_WRITE|FILE_TXT);

   FileWrite(handle_w2,W_2);
   FileClose(handle_w2);


   return true;
  };

void NeuralNetwork::ResetWeights(void)
  {

   matrix random_W1(m_depth, m_deep);
   matrix random_W2(m_deep, m_outDim);

   MatrixRandom(random_W1);
   MatrixRandom(random_W2);

   W_1      =   random_W1;
   W_2      = random_W2;
  }

void NeuralNetwork::ComputeDerivatives(matrix &Input, matrix &y_)
  {

   matrix X = Input;
   matrix Y = y_;

   m_yHat = Forward_Prop(X);

//Print( m_yHat.Cols(),m_yHat.Rows() );


   matrix cost =-1*(Y-m_yHat);

   z_3_prime = MatrixSigmoidPrime(m_z_3);

   delta3 = cost*(z_3_prime);

   dJdW2 = m_a_2.Transpose().MatMul(delta3);


   z_2_prime = MatrixSigmoidPrime(m_z_2);
   delta2 = delta3.MatMul(W_2.Transpose())*z_2_prime;


   dJdW1 = m_input.Transpose().MatMul(delta2);

  };

NeuralNetwork::NeuralNetwork(int in_DimensionRow,int in_DimensionCol,int Number_of_Neurons,int out_Dimension,double alpha,double LearningRate,bool Verbose, double beta_1, double beta_2,int max_iterations)
  {

   m_depth = in_DimensionCol;
   m_deep  = Number_of_Neurons;
   m_alpha = alpha;
   m_outDim= out_Dimension;
   m_LearningRate = LearningRate;
   m_beta_1 = beta_1;
   m_beta_2 = beta_2;
   matrix random_W1(m_depth, m_deep);
   matrix random_W2(m_deep, out_Dimension);

   m_verbose = Verbose;
   m_maxiters =max_iterations;
   MatrixRandom(random_W1);
   MatrixRandom(random_W2);

   W_1      =   random_W1;
   W_2      = random_W2;

   Print(W_1);
   Print(W_2);

  }

matrix NeuralNetwork::Prediction(matrix& Input)
  {

   m_pred_input = Input;

   matrix pred_z_2 = m_pred_input.MatMul(W_1) ;  ;


   matrix pred_a_2 = MatrixSigmoid(pred_z_2);

   matrix pred_z_3 = pred_a_2.MatMul(W_2);

   matrix pred_yHat = MatrixSigmoid(pred_z_3);


   return pred_yHat;
  }

void NeuralNetwork::Train(matrix &Input,matrix &correct_Val)
  {

   bool Train_condition = true;
   y_cor = correct_Val;
   int iterations = 0 ;

   m_yHat= Forward_Prop(Input);
   ComputeDerivatives(Input,y_cor);

   matrix mt_1(W_1.Rows(),W_1.Cols());
   mt_1.Fill(0);


   matrix mt_2(W_2.Rows(),W_2.Cols());
   mt_2.Fill(0);

   double J = 0;
   
   while(Train_condition && iterations <m_maxiters)
     {

      m_yHat= Forward_Prop(Input);
      ComputeDerivatives(Input,y_cor);
      J = Cost(Input,y_cor);

      if(J < m_alpha)
        {
         Train_condition = false;
        }

      double beta_1 = m_beta_1;
      double beta_2 = m_beta_2;
      mt_1 = beta_1*mt_1 +(1-beta_1)*(dJdW1);
      mt_2 = beta_1*mt_2 +(1-beta_1)*(dJdW2);

      W_1 = W_1 - m_LearningRate*(beta_2*mt_1);
      W_2 = W_2 - m_LearningRate*(beta_2*mt_2);

      iterations++;
     }

   if(m_verbose == true)
     {
      Print(iterations,"<<<< iterations");
      Print(J,"<<<< cost_value");
     }
  }

double NeuralNetwork::Cost(matrix &Input, matrix &y_)
  {
   matrix X = Input;
   matrix Y = y_;
   m_yHat = Forward_Prop(X);

   matrix temp = (Y -m_yHat);
   temp = temp*temp;  /// temp^2
   double J = .5*(temp.Sum()/(temp.Cols()*temp.Rows()));
   
   return J;
  }

matrix NeuralNetwork::Forward_Prop(matrix& Input)
  {
   m_input = Input;

   m_z_2 = m_input.MatMul(W_1);   ;

   m_a_2 = MatrixSigmoid(m_z_2);

   m_z_3 = m_a_2.MatMul(W_2);

   matrix yHat = MatrixSigmoid(m_z_3);

   return yHat;
  }

double NeuralNetwork::Sigmoid(double x)
  {
   return(1/(1+MathExp(-x)));
  }

double NeuralNetwork::Sigmoid_Prime(double x)
  {
   return(MathExp(-x)/(pow(1+MathExp(-x),2)));
  }

int NeuralNetwork::Sgn(double Value)
  {
   int res;

   if(Value>0)
     {
      res = 1;

     }
   else
     {
      res = -1;
     }
   return res;
  }

void NeuralNetwork::MatrixRandom(matrix& m)
  {
   int error;
   for(ulong r=0; r<m.Rows(); r++)
     {
      for(ulong c=0; c<m.Cols(); c++)
        {

         m[r][c]= MathRandomNormal(0,1,error);
        }
     }
  }

matrix NeuralNetwork::MatrixSigmoid(matrix& m)
  {
   matrix m_2;
   m_2.Init(m.Rows(),m.Cols());
   for(ulong r=0; r<m.Rows(); r++)
     {
      for(ulong c=0; c<m.Cols(); c++)
        {
         m_2[r][c]=Sigmoid(m[r][c]);
        }
     }
   return m_2;
  }

matrix NeuralNetwork::MatrixSigmoidPrime(matrix& m)
  {
   matrix m_2;
   m_2.Init(m.Rows(),m.Cols());
   for(ulong r=0; r<m.Rows(); r++)
     {
      for(ulong c=0; c<m.Cols(); c++)
        {
         m_2[r][c]= Sigmoid_Prime(m[r][c]);
        }
     }
   return m_2;
  }