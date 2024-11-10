from random import randrange
q = 8380417
GAMMA2 = (q-1) // 32
BETA = 120

# Prepare input vectors for vector arithmetic subfunctions
a = [randrange(q) for _ in range(256)]
b = [randrange(q) for _ in range(256)]

a_str = ['0x' + '{:08X}'.format(num) for num in a]
b_str = ['0x' + '{:08X}'.format(num) for num in b]

print("vector a is:")
print(a_str)
print("vector b is:")
print(b_str)

# Result for vector addition
c = [(a[i] + b[i]) % q for i in range(256)]
c_str = ['0x' + '{:08X}'.format(num) for num in c]
print("result a + b % q:")
print(c_str)

# Result for vector subtraction
c = [(a[i] - b[i]) % q for i in range(256)]
c_str = ['0x' + '{:08X}'.format(num) for num in c]
print("result a - b % q:")
print(c_str)

# Result for vector coefficient wise multiplication
c = [(a[i] * b[i]) % q for i in range(256)]
c_str = ['0x' + '{:08X}'.format(num) for num in c]
print("result a * b % q:")
print(c_str)

# Result for vector multiply accumulate
c = 0
for i in range(256):
    c += a[i] * b[i]
    c = c % q

c_str = '0x' + '{:08X}'.format(c)
print("result MAC(a, b) % q:")
print(c_str)

# Test vectors for decompose
r = randrange(q)
r = 0x006141C6
r1  = (r + 127) >> 7
r1  = r1*1025
r1  = r1 + (1 << 21)
r1  = r1 >> 22
r1 &= 15

r0  = r - r1*2*GAMMA2
print("r0: " + '0x' + '{:08X}'.format(r0))
r0 -= (((q-1) // 2 - r0) >> 31) & q
print("r0: " + '0x' + '{:08X}'.format(r0))

print("Decomopose test input / results:")
print("r: " + '0x' + '{:08X}'.format(r))
print("r0: " + '0x' + '{:08X}'.format(r0))
print("r1: " + '0x' + '{:08X}'.format(r1))

# Test vectors for rejection sampling
passing = [randrange(GAMMA2 - BETA) for _ in range(256)]
failing = [randrange(q) for _ in range(256)]
# Make sure there's at least one value which is gte (GAMMA2 - BETA)
failing[255] = GAMMA2 - BETA

passing_str = ['0x' + '{:08X}'.format(num) for num in passing]
failing_str = ['0x' + '{:08X}'.format(num) for num in failing]

print("Passing vector:")
print(passing_str)
print("Failing vector:")
print(failing_str)
