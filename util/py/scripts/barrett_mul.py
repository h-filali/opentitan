from random import randrange
q = 8380417
R = 2**64 // q
print(R)
a = randrange(q)
b = randrange(q)
res_mod = a*b % q
print("res_mod is: ", str(res_mod))

c = a*b
res_barr = c % (2**31)
res_barr *= R
res_barr = res_barr % (2**33)
res_barr *= q
res_barr = c - res_barr
res_barr = res_barr % q
print("res_barr is: ", str(res_barr))

