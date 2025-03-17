#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define uint128_t __uint128_t

#define DIL_Q 8380417
#define DIL_Q_PRIME 134086672
#define ALPHA 4
//We assume alpha = 4 which means we can go up to 15 shares

#define MU 23
#define K_APPROX 41
#define A_APPROX 262401
#define K_EXACT 50
#define A_EXACT 134348913


uint32_t rand32(){
  return rand();
}

void refreshArithModp(uint32_t a[],uint32_t p,int n)
{
  for(int i=0;i<n-1;i++)
  {
    uint32_t tmp=rand32() % p; //rand();
    a[n-1]=(a[n-1] + tmp) % p;
    a[i]=(a[i] + p - tmp) % p;
  }
}

// Boolean to arithmetic, 1 bit as input, and modulo q as ouptput
// This is Algorithm 1 in signatures.pdf, and corresponds to [SPOG19]
// We consider the NI version, without the last LinearRefresh
void bool2ArithSPOGmodq(uint32_t *x,uint32_t *y,int q,int n)
{
  y[0]=x[0];
  for(int i=1;i<n;i++)
  {
    y[i]=0;
    refreshArithModp(y,q,i+1);
    for(int j=0;j<(i+1);j++)
      y[j]=(q+y[j]*(1-2*x[i])) % q;
    y[0]=(y[0]+x[i]) % q;
  }
}

void generic_1bit_shift(uint32_t* x, uint32_t* y, int q, int n){
  /* Shift of 1 bit from mod q to mod q/2 for any even q*/
  uint32_t b[n], a[n], z[n];

  for(int i=0; i < n; ++i) b[i] = x[i]&1;
  bool2ArithSPOGmodq(b, a, q, n);


  for(int i=0; i < n; ++i) z[i] = (x[i] + q - a[i])%q;

  for(int i=0; i < n-1; ++i){
    z[n-1] = (z[n-1]   + (z[i]&1))%q;
    z[i]   = (z[i] + q - (z[i]&1))%q;
  }
  for(int i=0; i < n; ++i) y[i] = z[i]>>1;
}

void generic_shift(uint32_t* x, uint32_t* y, int k, int q, int n){
  /* Shift of k bits from mod 2^k * q to mod q for any q*/
  for(int i=0; i < (k>>1); ++i){
    generic_1bit_shift(x, y, (1<<(k-2*i))*q, n);
    generic_1bit_shift(y, x, (1<<(k-(2*i+1)))*q, n);
  }
  if (k&1){
    generic_1bit_shift(x, y, 2*q, n);
  } else {
    for(int i=0; i < n; ++i) y[i] = x[i];
  }

}

void exact_modulus_switching(uint64_t* x, uint32_t* y, int n){
  //assume alpha = 4
  uint32_t k = K_EXACT;
  uint32_t a = A_EXACT;
  uint128_t temp;
  uint32_t z[n];
  

  for(int i=0; i < n; ++i){
    temp = (uint128_t)x[i]*a*DIL_Q;
    temp >>= (k-ALPHA);
    z[i] = (uint32_t)(temp % DIL_Q_PRIME);
  }
  z[0] = (z[0] + n - 1)%DIL_Q_PRIME;
  generic_shift(z, y, ALPHA, DIL_Q, n);
}

void copy64(uint64_t *x,uint64_t *y,int n)
{
  for(int i=0;i<n;i++) x[i]=y[i];
}

uint64_t rand64(){

  return ((uint64_t)rand32() << 32) + (uint64_t)rand32();
}

uint64_t Psi64(uint64_t x,uint64_t y)
{
  return (x ^ y)-y;
}

uint64_t Psi064(uint64_t x,uint64_t y,int n)
{
  return Psi64(x,y) ^ ((~n & 1) * x);
}

void refreshBool64(uint64_t a[],int n)
{
  for(int i=0;i<n-1;i++)
  {
    uint64_t tmp=rand64();
    a[n-1]=a[n-1] ^ tmp;
    a[i]=a[i] ^ tmp;
  }
}

// here, x contains n+1 shares
static void impconvBA_rec64(uint64_t *D_,uint64_t *x,int n)
{  
  if (n==2)
  {
    uint64_t r1=rand64();
    uint64_t r2=rand64();
    uint64_t y0=(x[0] ^ r1) ^ r2;
    uint64_t y1=x[1] ^ r1;
    uint64_t y2=x[2] ^ r2;
    
    uint64_t z0=y0 ^ Psi64(y0,y1);
    uint64_t z1=Psi64(y0,y2);
    
    D_[0]=y1 ^ y2;
    D_[1]=z0 ^ z1;
     
    return;
  }

  uint64_t y[n+1];
  copy64(y,x,n+1);

  refreshBool64(y,n+1);

  uint64_t z[n];

  z[0]=Psi064(y[0],y[1],n);
  for(int i=1;i<n;i++)
    z[i]=Psi64(y[0],y[i+1]);

  uint64_t A[n-1],B[n-1];
  impconvBA_rec64(A,y+1,n-1);
  impconvBA_rec64(B,z,n-1);
  
  for(int i=0;i<n-2;i++)
    D_[i]=A[i]+B[i];

  D_[n-2]=A[n-2];
  D_[n-1]=B[n-2];
}

void impconvBA64(uint64_t *D_,uint64_t *x,int n)
{
  uint64_t x_ext[n+1];
  copy64(x_ext,x,n);
  x_ext[n] = 0;
  impconvBA_rec64(D_, x_ext, n);
}

void gen_y(uint32_t* y, int n){
  int k=K_EXACT;
  uint64_t x[n];
  uint64_t arith_x[n];

  for(int i=0; i < n; ++i) x[i] = rand32()%(1<<MU);

  x[0] = 6488641;
  x[1] = 4999553;

  printf("BEFORE: %lx \n", x[0] ^ x[1]);

  impconvBA64(arith_x, x, n);
  for(int i=0; i < n; ++i) arith_x[i] %= (1LLU<<k);


  exact_modulus_switching(arith_x, y, n);
  y[0] = (y[0] + DIL_Q - (1<<(MU-1)))%DIL_Q;

  printf("AFTER: %lx\n", (x[0] + x[1]) % DIL_Q);

}

int main(void) {
    int n = 2;
    uint32_t y[n];
    gen_y(y, n);
    printf("hello world\n");
}
