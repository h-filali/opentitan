from random import randrange
import time

MODULUS = 8380417
d = 2
k_q = 23
GAMMA2 = (MODULUS-1) // 32

time_a2b = 0
time_b2a = 0
time_a2b_b2a = 0
time_sec_add = 0
time_sec_add_mod = 0

def xor(a, b):
    c = [0 for _ in range(d)]
    for i in range(d):
        c[i] = a[i] ^ b[i]

    return c

def unmaskB(a):
    c = 0
    for i in range(d):
        c ^= a[i]

    return c

def unmaskA(a, q=MODULUS):
    c = 0
    for i in range(d):
        c += a[i]

    return c % q

def unmaskB(a, k=k_q):
    c = 0
    for i in range(d):
        c ^= a[i]
    
    assert c == (c % (1 << k))
    return c

def secUnmask(a, k):
    refresh(a, k)
    return unmaskB(a)

def secAnd(a, b):
    c = [0 for _ in range(d)]
    r  = [[0 for _ in range(d)] for _ in range(d)]
    s  = [[0 for _ in range(d)] for _ in range(d)]
    p0 = [[0 for _ in range(d)] for _ in range(d)]
    p1 = [[0 for _ in range(d)] for _ in range(d)]
    z  = [[0 for _ in range(d)] for _ in range(d)]

    for i in range(d):
        for j in range(i+1, d):
            # r[i][j] = randrange(2)
            r[i][j] = 1
            r[j][i] = r[i][j]

    for i in range(d):
        for j in range(d):
            if j == i:
                continue
            s[i][j]  = b[j] ^ r[i][j]
            p0[i][j] = (a[i] & r[i][j]) ^ r[i][j]
            p1[i][j] = a[i] & s[i][j]
            z[i][j]  = p0[i][j] ^ p1[i][j]

    for i in range(d):
        c[i] = a[i] & b[i]
        for j in range(d):
            if j == i:
                continue
            c[i] ^= z[i][j]
        assert c[i] == (a[i] & b[i]) ^ z[i][(i+1)%2]

    return c

def secFullAdder(x, y, z):
    for i in range(d):
        assert x[i] <= 1 and y[i] <= 1 and z[i] <= 1

    a = [0 for _ in range(d)]
    b = [0 for _ in range(d)]
    w  = [[0 for _ in range(d)] for _ in range(d)]

    for i in range(d):
        a[i] = x[i] ^ y[i]
        b[i] = x[i] ^ z[i]

    for i in range(d):
        w[0][i] = z[i] ^ a[i]

    ab_temp = secAnd(a, b)
    assert (ab_temp[0] ^ ab_temp[1]) == ((a[0] ^ a[1]) & (b[0] ^ b[1]))

    for i in range(d):
        w[1][i] = x[i] ^ ab_temp[i]
    
    return w

def secAdd(x, y, k):
    global time_sec_add
    t0 = time.time()

    c     = [0 for _ in range(d)]
    x_bit = [0 for _ in range(d)]
    y_bit = [0 for _ in range(d)]
    z     = [0 for _ in range(d)]

    for i in range(k-1):
        for j in range(d):
            x_bit[j] = (x[j] >> i) & 1
            y_bit[j] = (y[j] >> i) & 1

        t = secFullAdder(x_bit, y_bit, c)
        c = t[1]

        for j in range(d):
            z[j] = z[j] | (t[0][j] << i)

    for j in range(d):
        x_bit[j] = (x[j] >> (k-1)) & 1
        y_bit[j] = (y[j] >> (k-1)) & 1
        z_bit = x_bit[j] ^ y_bit[j] ^ c[j]
        z[j] = z[j] | (z_bit << (k-1))

    t1 = time.time()
    time_sec_add += t1-t0

    assert (z[0] ^ z[1]) < (2<<k)
    return z

def bitCopyMask(b, k, q=MODULUS):
    for i in range(d):
        assert b[i] <= 1

    x = [0 for _ in range(d)]
    y = [0 for _ in range(d)]

    for i in range(d):
        x[i] = (b[i] << k) - b[i]
        y[i] = x[i] & q

    return y

def secAddModp(x, y, k, q=MODULUS):
    global time_sec_add_mod
    t0 = time.time()

    p = [0 for _ in range(d)]
    b = [0 for _ in range(d)]

    p[0] = (1 << (k+1)) - q
    s = secAdd(x, y, k+1)
    assert (s[0] ^ s[1]) == (((x[0] ^ x[1]) + (y[0] ^ y[1])) % (2 << (k+1)))
    sp = secAdd(s, p, k+1)
    assert (sp[0] ^ sp[1]) == (((s[0] ^ s[1]) + (p[0] ^ p[1])) % (2 << k))

    for i in range(d):
        b[i] = (sp[i] >> k) & 1
    
    a = bitCopyMask(b, k, q)
    assert (a[0] == b[0]*q) and (a[1] == b[1]*q)

    z = secAdd(a, sp, k)
    assert (z[0] ^ z[1]) == (((sp[0] ^ sp[1]) + (a[0] ^ a[1])) % (2 << (k-1)))

    t1 = time.time()
    time_sec_add_mod += t1-t0

    return z

def refresh(x, k):
    r = randrange(2<<k)
    y[0] = x[0] ^ r
    y[1] = x[1] ^ r

    return y

def secA2BModp(x, k, q=MODULUS):
    global time_a2b
    t0 = time.time()

    y  = [x[0], 0]
    sp = [0, x[1]]
    p  = [(2<<k) - q, 0]
    b  = [0 for _ in range(d)]

    s = secAdd(p, y, k+1)
    u = secAdd(s, sp, k+1)

    for i in range(d):
        b[i] = (u[i] >> k) & 1

    a = bitCopyMask(b, k, q)
    z = secAdd(a, u, k)

    t1 = time.time()
    time_a2b += t1-t0

    return z

def secB2AModp(x, k, q=MODULUS):
    global time_b2a
    t0 = time.time()

    z  = [0 for _ in range(d)]
    zp = [0 for _ in range(d)]

    z[0]  = randrange(q)
    zp[0] = q - z[0]

    a = secA2BModp(zp, k, q)
    b = secAddModp(a, x, k, q)
    c = refresh(b, k)
    z[1] = c[0] ^ c[1]

    t1 = time.time()
    time_b2a += t1-t0

    return z

def secLinearRefresh(x, q=MODULUS):
    r = randrange(q)
    y[0] = (x[0] + r) % q
    y[1] = (x[1] - r) % q

    return y

def sec1BitB2A(q, x):
    v = [0 for _ in range(d)]

    x.append(x[0])
    v[0] = x[1]

    v = secLinearRefresh([v[0], 0], q)
    
    for i in range(d):
        v[i] = ((1 - 2*x[2]) * v[i]) % q

    v[0] = (v[0] + x[2]) % q

    v = secLinearRefresh(v, q) 

    return v


def secShiftMod(q, x):
    b = [0 for _ in range(d)]
    z = [0 for _ in range(d)]
    a = [0 for _ in range(d)]

    x_unmasked = ((x[0] + x[1]) >> 1) % q
    
    for i in range(d):
        b[i] = x[i] & 1

    y = sec1BitB2A(2*q, b)

    for i in range(d):
        z[i] = (x[i] - y[i]) % (2*q)

    z[1] = z[1] + (z[0] & 1) % (2*q)
    z[0] = z[0] - (z[0] & 1) % (2*q)

    for i in range(d):
        a[i] = z[i] >> 1

    a_unmasked = (a[0] + a[1]) % q

    print("secShiftMod x unmasked: ", hex(x_unmasked))
    print("secShiftMod a unmasked: ", hex(a_unmasked))

    assert a_unmasked == x_unmasked

    print("secShiftMod a unmasked: ", hex(a[0]), hex(a[1]))

    return a

def refreshMasks(x, k):
    l = len(x)
    y = [0 for _ in range(l)]
    y[0] = x[0]

    for i in range(1, l):
        r = randrange(1<<k)
        y[i] = x[i] ^ r
        y[0] = y[0] ^ r

    x_check = 0
    y_check = 0
    for i in range(l):
        x_check = x_check ^ x[i]
        y_check = y_check ^ y[i]

    assert x_check == y_check

    return y

def secB2AExp(x, k):
    z = [0 for _ in range(d)]
    res = [0 for _ in range(d)]

    y = refreshMasks(x, k)
    z[0] = (y[0] ^ ((y[0] ^ y[1]) - y[1])) % (1 << k)
    z[1] = ((y[0] ^ y[2]) - y[2]) % (1 << k)

    a = y[1] ^ y[2]
    b = z[0] ^ z[1]

    res[0] = a
    res[1] = b

    assert (x[0] ^ x[1]) == ((res[0] + res[1]) % (1<<k))

    return res

def secB2AModpExact(u, k, q=MODULUS):
    alpha = 1
    mu = 23
    k = 23 + mu + alpha
    qp = q * (1 << alpha)
    a = ((1 << k) + (q-1)) // q
    assert a == 16793615
    y = [0 for _ in range(d)]

    u.append(0)
    x = secB2AExp(u, mu)
    print("after secB2A x: ", hex(x[0]), hex(x[1]), hex((x[0] + x[1]) % (1<<mu)))

    for i in range(d):
        y[i] = ((x[i] * a * q) >> (k - alpha)) % qp
    
    y[0] += 1

    x_unmasked = ((y[0] + y[1]) >> 1) % q

    print("before ShifMod x: ", hex(y[0]), hex(y[1]), hex(x_unmasked))

    y = secShiftMod(qp, y)

    return y

def refreshArithModp(a, p, n):

    for i in range(n-1):
        tmp = randrange(p)
        a[n-1] = (a[n-1] + tmp) % p
        a[i] = (a[i] + p - tmp) % p

    return a

def bool2ArithSPOGmodq(x, y, q, n):
    y[0]=x[0]

    for i in range(n):
        y[i]=0
        y = refreshArithModp(y,q,i+1)

        for j in range(i+1):
            y[j]=(q+y[j]*(1-2*x[i])) % q

        y[0]=(y[0]+x[i]) % q
    
    return [x, y]

def generic_1bit_shift(x, y, q, n):
    # Shift of 1 bit from mod q to mod q/2 for any even q
    b = [0 for _ in range(d)]
    a = [0 for _ in range(d)]
    z = [0 for _ in range(d)]

    for i in range(n):
        b[i] = x[i]&1

    [b, a] = bool2ArithSPOGmodq(b, a, q, n)

    for i in range(n):
        z[i] = (x[i] + q - a[i]) % q

    for i in range(n):
        z[n-1] = (z[n-1]   + (z[i]&1)) % q
        z[i]   = (z[i] + q - (z[i]&1)) % q
    
    for i in range(n):
        y[i] = z[i]>>1
    
    return [x, y]

def generic_shift(x, k, q, n):
    y = [0 for _ in range(d)]

    # Shift of k bits from mod 2^k * q to mod q for any q
    for i in range(k>>1):
        [x, y] = generic_1bit_shift(x, y, (1<<(k-2*i))*q, n)
        [y, x] = generic_1bit_shift(y, x, (1<<(k-(2*i+1)))*q, n)

    if (k&1):
        [x, y] = generic_1bit_shift(x, y, 2*q, n)
    else:
        for i in range(n):
            y[i] = x[i]

    return y

def secB2A2k(x, q=MODULUS, k=k_q, d=d):
    z = [0 for _ in range(d)]

    x_unmasked = x[0] ^ x[1]

    gamma = randrange(1<<(k-1))
    a1 = x[0]
    a2 = x[0] ^ gamma
    a3 = x[1] + gamma
    a4 = x[1] ^ gamma

    z[0] |= a3 & 1
    z[0] |= (((a3 >> 1) & 1) ^ ((a1 & 1) & ~(a4 & 1))) << 1

    for i in range(2, k):
        z_temp = ((a3 >> i) & 1) ^ (((a1 >> (i-1)) & 1) & ~((a4 >> (i-1)) & 1))
        
        for d in range(3, i+2):
            j = i + 1 - d
            t = ((a1 >> j) & 1) & ~((a4 >> j) & 1)

            for m in range(d-2, 0, -1):
                t &= ((a4 >> (j+m)) & 1)
            
            z_temp = z_temp ^ t

        z[0] |= z_temp << i

    z[1] = a2

    z_unmasked = (z[0] - z[1])

    assert z[0] == (x_unmasked + (x[0] ^ gamma))
    assert z[1] == (x[0] ^ gamma)
    assert x_unmasked == z_unmasked

    return z

def DOMf(a0, a1, b0, b1, c0, c1, r0, r1):
    y0p = (a0 & b0) ^ c0 ^ r1
    y1p = (a0 & b1) ^ r0
    y2p = (a1 & b0) ^ r0
    y3p = (a1 & b1) ^ c1 ^ r1

    y0 = y0p ^ y1p
    y1 = y2p ^ y3p

    return [y0, y1]

def DomAnd(a0, a1, b0, b1):
    r0 = randrange(2)
    # r0 = 0
    return DOMf(a0, a1, b0, b1, 0, 0, r0, 0)

def DomAndURefresh(a0, a1, b0, b1, ui, uim1):
    r0 = randrange(2)
    r1 = randrange(2)
    # r0 = 0
    # r1 = 0
    n = DOMf(a0, a1, b0, b1, 0, 0, r0, r1)
    m = [uim1 & i for i in n]
    l = [ui & a0, ui & a1]
    k = [ui & uim1 & b0, ui & uim1 & b1]
    return [m[0] ^ l[0] ^ k[0], m[1] ^ l[1] ^ k[1]]

# def DomAndRefresh(a0, a1, b0, b1, r0, r1):
#     return DOMf(a0, a1, b0, b1, 0, 0, r0, r1)

def DomAndXorRefresh(a0, a1, b0, b1, c0, c1):
    r0 = randrange(2)
    r1 = randrange(2)
    r0 = 0
    r1 = 0
    return DOMf(a0, a1, b0, b1, c0, c1, r0, r1)

def KSABorrowBitGen(x, q=MODULUS, k=k_q):
    a  = [0 for _ in range(d)]
    p  = [0 for _ in range(d)]
    g  = [0 for _ in range(d)]

    # Refresh even bits and set a to the refreshed bits.
    for i in range(0, k-1, 2):
        r = randrange(2)
        # r = 0
        a[0] |= (((x[0] >> i) & 1) ^ r) << i
        a[1] |= (((x[1] >> i) & 1) ^ r) << i

    # Don't refresh odd bits and set a to the non-refreshed bits.
    for i in range(1, k, 2):
        a[0] |= x[0] & (1 << i)
        a[1] |= x[1] & (1 << i)

    # u = -q % 2^k
    u = (1 << k) - q
    x_unmasked = x[0] ^ x[1]
    # print("u is", hex(u))
    # print("a0 is", hex(a[0]))
    # print("a1 is", hex(a[1]))
    # print("x_unmasked", hex(x_unmasked))

    mask = (1<<k) - 1

    # Add u = -q to x.
    for i in range(1, k, 2):
        a0i = (a[0] >> i) & 1
        a0im1 = (a[0] >> (i-1)) & 1
        a1i = (a[1] >> i) & 1
        a1im1 = (a[1] >> (i-1)) & 1
        ui = (u >> i) & 1
        uim1 = (u >> (i-1)) & 1
        xi = (x_unmasked >> i) & 1
        xim1 = (x_unmasked >> (i-1)) & 1

        p_temp = DomAnd(a0i ^ ui, a1i, a0im1 ^ uim1, a1im1)
        assert (p_temp[0] ^ p_temp[1]) == ((uim1 ^ xim1) & (ui ^ xi))

        p[0] |= p_temp[0] << i
        p[1] |= p_temp[1] << i

        g_temp = DomAndURefresh(a0i, a1i, a0im1, a1im1, ui, uim1)
        assert (g_temp[0] ^ g_temp[1]) == ((uim1 & xim1 & xi) ^ (ui & xi) ^ (uim1 & ui & xim1))

        g[0] |= g_temp[0] << i
        g[1] |= g_temp[1] << i
    
    # print("g0 is", hex(g[0]))
    # print("g1 is", hex(g[1]))
    # print("p0 is", hex(p[0]))
    # print("p1 is", hex(p[1]))
    # print("g is", hex(g[0]^g[1]))
    # print("p is", hex(p[0]^p[1]))


    for j in range(2, 5):
        alpha = k
        beta = 1 << (j-1)

        for i in range(1, k // (2*j)):
            m = alpha - 1
            l = alpha - beta - 1

            if l < 0: continue

            t0 = (p[0] >> m) & 1
            t1 = (p[1] >> m) & 1

            p_temp = DomAnd(t0, t1, (p[0] >> l) & 1, (p[1] >> l) & 1)
            
            p_rec = p_temp[1] ^ p_temp[0]
            p_exp = (t0 ^ t1) & (((p[0] >> l) & 1) ^ ((p[1] >> l) & 1))
            assert p_rec == p_exp

            p[0] &= (mask - (1 << m))
            p[1] &= (mask - (1 << m))
            # print("mask", hex(mask - (1 << m)))
            p[0] |= p_temp[0] << m
            p[1] |= p_temp[1] << m

            g_temp = DomAndXorRefresh(t0, t1,
                                      (g[0] >> l) & 1, (g[1] >> l) & 1,
                                      (g[0] >> m) & 1, (g[1] >> m) & 1)
            
            g_rec = g_temp[1] ^ g_temp[0]
            g_exp = ((t0 ^ t1) & (((g[0] >> l) & 1) ^ ((g[1] >> l) & 1))) ^ (((g[0] >> m) & 1) ^ ((g[1] >> m) & 1))
            assert g_rec == g_exp

            g[0] &= (mask - (1 << m))
            g[1] &= (mask - (1 << m))
            g[0] |= g_temp[0] << m
            g[1] |= g_temp[1] << m

            alpha -= 2*beta
    
        # print("g0 stage", j, "is", hex(g[0]))
        # print("g1 stage", j, "is", hex(g[1]))
        # print("p0 stage", j, "is", hex(p[0]))
        # print("p1 stage", j, "is", hex(p[1]))
        # print("g stage", j, "is", hex(g[0]^g[1]))
        # print("p stage", j, "is", hex(p[0]^p[1]))

    b = DomAndXorRefresh((p[0] >> (k-1)) & 1,
                         (p[1] >> (k-1)) & 1,
                         (g[0] >> 7) & 1,
                         (g[1] >> 7) & 1,
                         (g[0] >> (k-1)) & 1,
                         (g[1] >> (k-1)) & 1)
    
    # Check if the result is what we expect.
    if x_unmasked < q:
        assert (b[0] ^ b[1]) == 0
    else:
        assert (b[0] ^ b[1]) == 1

    # print("b is", b)
    
    return b




def secB2Aq(x, q=MODULUS):
    w  = [0 for _ in range(d)]
    z  = [0 for _ in range(d)]

    # x_unmasked = x[0] ^ x[1]

    t = secB2A2k(x, q, k_q+1)
    # print("this is t", hex(t[0]), hex(t[1]))
    u = t[1] + q
    b = KSABorrowBitGen(x, q, k_q+1)
    b = [(bit << (k_q+1)) - bit for bit in b]
    w[0] = (b[0] & (t[1] ^ u)) ^ t[1]
    w[1] = (b[1] & (t[1] ^ u))

    assert t[0] < 2*q
    assert (w[0] ^ w[1]) < 2*q

    z[0] = t[0] % q
    z[1] = (w[0] ^ w[1]) % q
    z[1] = (q - z[1]) % q

    return z

# Inputs:
# - Boolean sharing x
# - Value for comparison phi
# - Number of bits per share k
# Outputs:
# - Bool which is 1 if x <= phi and 0 otherwise
def secLeq(x, phi, k):
    b  = [0 for _ in range(d)]

    temp = [(1 << (k+1)) - phi - 1, 0]
    xp = secAdd(x, temp, k+1)

    for i in range(d):
        b[i] = (xp[i] >> k) & 1

    return secUnmask(b, 1)

# Inputs:
# - Boolean sharing x
# - Value for comparison l0 and l1
# - Number of bits per share k
# Outputs:
# - Bool which is 1 if -l0 <= x <= l1 and 0 otherwise
def secSampleModp(x, l0, l1, k, q=MODULUS, gamma=44):
    x[0] = (x[0] + l0) % q
    xB = secA2BModp(x, k)
    return secLeq(xB, l0+l1, k)

def secDecompose(r, k, q=MODULUS, gamma=44):
    global time_a2b_b2a
    r0 = [0 for _ in range(d)]
    s  = [0 for _ in range(d)]

    const = ((MODULUS - gamma) *(2**64)) % q
    const = (const * 1732267787797143553) % (2**64)
    for i in range(d):
        s[i] = (-gamma * r[i]) % q
        print("s", i, hex(s[i]))
        res_plan = (const * r[i]) % (2**64)
        res_plan = res_plan >> 32
        res_plan += 1
        res_plan *= q
        res_plan = res_plan >> 32
        res_plan = (-1 * res_plan) % q
        assert s[i] == res_plan

    s[0] = (s[0] + (q-1)//2) % q

    t0 = time.time()

    sp = secA2BModp(s, k)
    print("sp0", hex(sp[0]))
    print("sp1", hex(sp[1]))
    print("sp", hex(sp[1] ^ sp[0]))
    spp = secB2AModp(sp, k, gamma)
    print("spp0", hex(spp[0]))
    print("spp1", hex(spp[1]))
    print("spp", hex(spp[1] ^ spp[0]))

    t1 = time.time()
    time_a2b_b2a += t1-t0

    # Barrett reduction
    sum = spp[0] + spp[1]
    r1 = (sum * 190650) >> 23
    r1 = sum - r1*44
    if r1 >= 44:
        r1 -= 44

    r0 = r
    r0[0] -= (r1 * (q-1)//gamma) % q
    r0[0] = r0[0] % q

    return [r0, r1]

# Secure AND test
a = [randrange(2) for _ in range(d)]
b = [randrange(2) for _ in range(d)]
c = secAnd(a,b)

c_unmasked_shares = 0
for val in c:
    c_unmasked_shares ^= val

a_unmasked = 0
for val in a:
    a_unmasked ^= val

b_unmasked = 0
for val in b:
    b_unmasked ^= val

c_unmasked = a_unmasked & b_unmasked

assert c_unmasked_shares == c_unmasked

# Secure Add test
x = [randrange(MODULUS) for _ in range(d)]
y = [randrange(MODULUS) for _ in range(d)]
z = secAdd(x,y,k_q+1)
z_exp = (x[0] ^ x[1]) + (y[0] ^ y[1])
assert (z[0] ^ z[1]) == z_exp

# Secure Addm test
z = secAddModp(x,y,k_q)
z_exp = ((x[0] ^ x[1]) + (y[0] ^ y[1])) % MODULUS
assert (z[0] ^ z[1]) == z_exp

# Secure A2B and B2A test
x_b = secA2BModp(x, k_q)
x_a = secB2AModp(x_b, k_q)
assert unmaskA(x) == unmaskA(x_a)

# SecLeq test
smaller = randrange(2)
phi = 524168
x = [randrange(MODULUS) for _ in range(d)]
x_b = secA2BModp(x, k_q)
b_exp = ((x_b[0] ^ x_b[1]) <= phi)

if smaller:
    while not b_exp:
        x = [randrange(MODULUS) for _ in range(d)]
        x_b = secA2BModp(x, k_q)
        b_exp = ((x_b[0] ^ x_b[1]) <= phi)

x_b = [0x520ee2, 0x7a179]
b_exp = ((x_b[0] ^ x_b[1]) <= phi)

time_a2b = 0
time_b2a = 0
time_sec_add = 0
time_sec_add_mod = 0
t0 = time.time()
b = secLeq(x_b, phi, k_q)
t1 = time.time()
total = t1-t0

print("SecLeq")
print("----------------------------------------------")
print("Time:                   ", 10**9 * total, "ns")
print("Time A2B:               ", 10**9 * time_a2b, "ns")
print("Time w/o A2B:           ", 10**9 * (total - time_a2b), "ns")
print("Time B2A:               ", 10**9 * time_b2a, "ns")
print("Time w/o B2A:           ", 10**9 * (total - time_b2a), "ns")
print("Time A2B and B2A:       ", 10**9 * time_a2b_b2a, "ns")
print("Time w/o A2B and B2A:   ", 10**9 * (total - time_a2b_b2a), "ns")
print("Time SEC_ADD:           ", 10**9 * time_sec_add, "ns")
print("Time w/o SEC_ADD:       ", 10**9 * (total - time_sec_add), "ns")
print("Time SEC_ADD_MOD_P:     ", 10**9 * time_sec_add_mod, "ns")
print("Time w/o SEC_ADD_MOD_P: ", 10**9 * (total - time_sec_add_mod), "ns")
print("----------------------------------------------")

assert b == b_exp

# Secure Decompose test
r = [randrange(MODULUS) for _ in range(d)]
# r = [1565403, 1233625]
r = [0x0051D03F, 0x001DE654]
print("r", r)
print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
print("r[0]", hex(r[0]))
print("r[1]", hex(r[1]))
r_unmasked = unmaskA(r)
s = (-44*r_unmasked + (MODULUS-1)//2) % MODULUS
r1  = s % 44
r0  = (r_unmasked - r1*(MODULUS-1)//44) % MODULUS

assert r_unmasked == ((r1*(MODULUS-1)//44) + r0) % MODULUS

total = 0
time_a2b = 0
time_b2a = 0
time_a2b_b2a = 0
time_sec_add = 0
time_sec_add_mod = 0

t0 = time.time()
[r0_act, r1_act] = secDecompose(r, k_q)
t1 = time.time()
total = t1-t0
print("r1_act", hex(r1_act))
print("r0_act[0]", hex(r0_act[0]))
print("r0_act[1]", hex(r0_act[1]))
print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")

# print("Decompose")
# print("----------------------------------------------")
# print("Time:                   ", 10**9 * total, "ns")
# print("Time A2B:               ", 10**9 * time_a2b, "ns")
# print("Time w/o A2B:           ", 10**9 * (total - time_a2b), "ns")
# print("Time B2A:               ", 10**9 * time_b2a, "ns")
# print("Time w/o B2A:           ", 10**9 * (total - time_b2a), "ns")
# print("Time A2B and B2A:       ", 10**9 * time_a2b_b2a, "ns")
# print("Time w/o A2B and B2A:   ", 10**9 * (total - time_a2b_b2a), "ns")
# print("Time SEC_ADD:           ", 10**9 * time_sec_add, "ns")
# print("Time w/o SEC_ADD:       ", 10**9 * (total - time_sec_add), "ns")
# print("Time SEC_ADD_MOD_P:     ", 10**9 * time_sec_add_mod, "ns")
# print("Time w/o SEC_ADD_MOD_P: ", 10**9 * (total - time_sec_add_mod), "ns")
# print("----------------------------------------------")

# print(hex(r0_act[0]), hex(r0_act[1]), hex(r0 % MODULUS), hex(r1_act))
# assert (r1 == r1_act) and (r0 % MODULUS == (r0_act[0] + r0_act[1]) % MODULUS)

# # Secure B2AExact test
# # u = [randrange(1 << k_q) for _ in range(d)]
# # u = [6488641, 4999553]
# # u_unmasked = unmaskB(u)
# # print("Boolean vector is", u)
# # print("Boolean vector unmasked is", hex(u_unmasked))

# # x = secB2AModpExact(u, k_q, MODULUS)
# # x_unmasked = unmaskA(x)
# # print("Arithmetic vector is", x)
# # print("Arithmetic vector unmasked is", hex(x_unmasked))

# # assert unmaskA(x) == unmaskB(u)

# # Secure B2AExact test
# for i in range(1000000):
#     # print("round", i)
#     while True:
#         u = [randrange(1 << k_q) for _ in range(d)]
#         if (u[0] ^ u[1]) < MODULUS:
#             break

#     u_unmasked = unmaskB(u)
#     # print("Boolean vector is", u)
#     # print("Boolean vector unmasked is", hex(u_unmasked))

#     r = randrange(1 << k_q)
#     x = secB2Aq(u, MODULUS)
#     x_unmasked = (x[0] + x[1]) % MODULUS
#     # print("Arithmetic vector is", hex(x[0]), hex(x[1]))
#     # print("Arithmetic vector unmasked is", hex(x_unmasked))

#     assert x_unmasked == u_unmasked


# u = [0x65d8db, 0x1a699f]

# x = secB2Aq(u, MODULUS)
