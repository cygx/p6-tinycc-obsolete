module TinyCC::Lib::C {
    use CTypes;
    use TinyCC::CCall;

    use TinyCC *;

    sub eval($code, *@includes) {
        tcc.reuse.include(@includes).compile($code, :x).run;
    }

    constant char   = cchar;
    constant short  = cshort;
    constant int    = cint;
    constant long   = clong;
    constant llong  = cllong;

    constant uchar   = cuchar;
    constant ushort  = cushort;
    constant uint    = cuint;
    constant ulong   = culong;
    constant ullong  = cullong;

    constant float  = cfloat;
    constant double = cdouble;

    constant int8_t   = cint8;
    constant int16_t  = cint16;
    constant int32_t  = cint32;
    constant int64_t  = cint64;
    constant intptr_t = cintptr;

    constant uint8_t   = cuint8;
    constant uint16_t  = cuint16;
    constant uint32_t  = cuint32;
    constant uint64_t  = cuint64;
    constant uintptr_t = cuintptr;

    constant size_t    = cuintptr;
    constant ptrdiff_t = cintptr;

    constant clock_t = do {
        given eval('sizeof (clock_t)', <time.h>) {
            when 4 {
                if eval('(clock_t)0.5 == 0.5', <time.h>) { float }
                else {
                    if eval('(clock_t)-1 < 0', <time.h>) { int32_t }
                    else { uint32 }
                }
            }
            when 8 {
                if eval('(clock_t)0.5 == 0.5', <time.h>) { double }
                else {
                    if eval('(clock_t)-1 < 0', <time.h>) { int64_t }
                    else { uint64_t }
                }
            }
            default { die "Unsupported clock_t size $_" }
        }
    }

    constant time_t = do {
        my \SIZE = eval('sizeof (time_t)', <time.h>);
        my \IS-FLOAT = eval('(time_t)0.5 == 0.5', <time.h>);
        my \IS-SIGNED = !IS-FLOAT && eval('(time_t)-1 < 0', <time.h>);

        given SIZE {
            when 4 {
                if IS-FLOAT { float }
                else {
                    if IS-SIGNED { int32 }
                    else { uint32 }
                }
            }
            when 8 {
                if IS-FLOAT { double }
                else {
                    if IS-SIGNED { int64 }
                    else { uint64 }
                }
            }
            default { die "Unsupported time_t size $_" }
        }
    }

    constant _IOFBF   = eval('_IOFBF', <stdio.h>);
    constant _IOLBF   = eval('_IOLBF', <stdio.h>);
    constant _IONBF   = eval('_IONBF', <stdio.h>);
    constant BUFSIZ   = eval('BUFSIZ', <stdio.h>);
    constant EOF      = eval('EOF', <stdio.h>);
    constant SEEK_CUR = eval('SEEK_CUR', <stdio.h>);
    constant SEEK_END = eval('SEEK_END', <stdio.h>);
    constant SEEK_SET = eval('SEEK_SET', <stdio.h>);

    constant Ptr = cvoidptr;
    constant &sizeof = &nativesizeof;

    our sub NULL { once Ptr.new(0) }

    # <ctype.h>
    our sub isalnum(int --> int) is native(LIBC) { * }
    our sub isalpha(int --> int) is native(LIBC) { * }
    our sub isblank(int --> int) is native(LIBC) { * }
    our sub iscntrl(int --> int) is native(LIBC) { * }
    our sub isdigit(int --> int) is native(LIBC) { * }
    our sub isgraph(int --> int) is native(LIBC) { * }
    our sub islower(int --> int) is native(LIBC) { * }
    our sub isprint(int --> int) is native(LIBC) { * }
    our sub ispunct(int --> int) is native(LIBC) { * }
    our sub isspace(int --> int) is native(LIBC) { * }
    our sub isupper(int --> int) is native(LIBC) { * }
    our sub isxdigit(int --> int) is native(LIBC) { * }
    our sub tolower(int --> int) is native(LIBC) { * }
    our sub toupper(int --> int) is native(LIBC) { * }

    # <errno.h>
    my constant @ERRNO-BASE =
        :EPERM(1),
        :ENOENT(2),
        :ESRCH(3),
        :EINTR(4),
        :EIO(5),
        :ENXIO(6),
        :E2BIG(7),
        :ENOEXEC(8),
        :EBADF(9),
        :ECHILD(10),
        :EAGAIN(11),
        :ENOMEM(12),
        :EACCES(13),
        :EFAULT(14),
        :ENOTBLK(15),
        :EBUSY(16),
        :EEXIST(17),
        :EXDEV(18),
        :ENODEV(19),
        :ENOTDIR(20),
        :EISDIR(21),
        :EINVAL(22),
        :ENFILE(23),
        :EMFILE(24),
        :ENOTTY(25),
        :ETXTBSY(26),
        :EFBIG(27),
        :ENOSPC(28),
        :ESPIPE(29),
        :EROFS(30),
        :EMLINK(31),
        :EPIPE(32),
        :EDOM(33),
        :ERANGE(34);

    my constant @ERRNO-WIN32 =
        :EDEADLK(36),
        :EDEADLOCK(36),
        :ENAMETOOLONG(38),
        :ENOLCK(39),
        :ENOSYS(40),
        :ENOTEMPTY(41),
        :EILSEQ(42),
        :STRUNCATE(80);

    my constant @ERRNO-LINUX =
        :EDEADLK(35),
        :ENAMETOOLONG(36),
        :ENOLCK(37),
        :ENOSYS(38),
        :ENOTEMPTY(39),
        :ELOOP(40),
        :EWOULDBLOCK(11),
        :ENOMSG(42),
        :EIDRM(43),
        :ECHRNG(44),
        :EL2NSYNC(45),
        :EL3HLT(46),
        :EL3RST(47),
        :ELNRNG(48),
        :EUNATCH(49),
        :ENOCSI(50),
        :EL2HLT(51),
        :EBADE(52),
        :EBADR(53),
        :EXFULL(54),
        :ENOANO(55),
        :EBADRQC(56),
        :EBADSLT(57),
        :EDEADLOCK(35),
        :EBFONT(59),
        :ENOSTR(60),
        :ENODATA(61),
        :ETIME(62),
        :ENOSR(63),
        :ENONET(64),
        :ENOPKG(65),
        :EREMOTE(66),
        :ENOLINK(67),
        :EADV(68),
        :ESRMNT(69),
        :ECOMM(70),
        :EPROTO(71),
        :EMULTIHOP(72),
        :EDOTDOT(73),
        :EBADMSG(74),
        :EOVERFLOW(75),
        :ENOTUNIQ(76),
        :EBADFD(77),
        :EREMCHG(78),
        :ELIBACC(79),
        :ELIBBAD(80),
        :ELIBSCN(81),
        :ELIBMAX(82),
        :ELIBEXEC(83),
        :EILSEQ(84),
        :ERESTART(85),
        :ESTRPIPE(86),
        :EUSERS(87),
        :ENOTSOCK(88),
        :EDESTADDRREQ(89),
        :EMSGSIZE(90),
        :EPROTOTYPE(91),
        :ENOPROTOOPT(92),
        :EPROTONOSUPPORT(93),
        :ESOCKTNOSUPPORT(94),
        :EOPNOTSUPP(95),
        :EPFNOSUPPORT(96),
        :EAFNOSUPPORT(97),
        :EADDRINUSE(98),
        :EADDRNOTAVAIL(99),
        :ENETDOWN(100),
        :ENETUNREACH(101),
        :ENETRESET(102),
        :ECONNABORTED(103),
        :ECONNRESET(104),
        :ENOBUFS(105),
        :EISCONN(106),
        :ENOTCONN(107),
        :ESHUTDOWN(108),
        :ETOOMANYREFS(109),
        :ETIMEDOUT(110),
        :ECONNREFUSED(111),
        :EHOSTDOWN(112),
        :EHOSTUNREACH(113),
        :EALREADY(114),
        :EINPROGRESS(115),
        :ESTALE(116),
        :EUCLEAN(117),
        :ENOTNAM(118),
        :ENAVAIL(119),
        :EISNAM(120),
        :EREMOTEIO(121),
        :EDQUOT(122),
        :ENOMEDIUM(123),
        :EMEDIUMTYPE(124),
        :ECANCELED(125),
        :ENOKEY(126),
        :EKEYEXPIRED(127),
        :EKEYREVOKED(128),
        :EKEYREJECTED(129),
        :EOWNERDEAD(130),
        :ENOTRECOVERABLE(131);

    my Int enum Errno ();
    my Errno @errno;

    BEGIN {
        @errno[.value] = TinyCC::Lib::C::{.key} :=
            Errno.new(:key(.key), :value(.value)) for flat do given KERNEL {
                when 'win32'|'mingw32' { @ERRNO-BASE, @ERRNO-WIN32 }
                when 'linux' { @ERRNO-BASE, @ERRNO-LINUX }
                default {
                    warn "Unknown kernel '$_'";
                    @ERRNO-BASE;
                }
            }
    }

    our proto errno(|) { * }

    multi sub errno() {
        sub p6_native_libc_errno_get(--> int32) is native(RTDLL) { * }
        my Int \value = p6_native_libc_errno_get;
        @errno[value] // value;
    }

    multi sub errno(Int \value) {
        sub p6_native_libc_errno_set(int) is native(RTDLL) { * }
        p6_native_libc_errno_set(value);
        @errno[value] // value;
    }

    # <limits.h>
    constant CHAR_BIT = tcc.sysinclude('limits.h').compile(:x, 'CHAR_BIT').run;

    do {
        sub p6_native_libc_limits_char_bit(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_char_bit;
    }

    constant SCHAR_MIN = do {
        sub p6_native_libc_limits_schar_min(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_schar_min;
    }

    constant SCHAR_MAX = do {
        sub p6_native_libc_limits_schar_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_schar_max;
    }

    constant UCHAR_MAX = do {
        sub p6_native_libc_limits_uchar_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_uchar_max;
    }

    constant CHAR_MIN = do {
        sub p6_native_libc_limits_char_min(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_char_min;
    }

    constant CHAR_MAX = do {
        sub p6_native_libc_limits_char_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_char_max;
    }

    constant MB_LEN_MAX = do {
        sub p6_native_libc_limits_mb_len_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_mb_len_max;
    }

    constant SHRT_MIN = do {
        sub p6_native_libc_limits_shrt_min(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_shrt_min;
    }

    constant SHRT_MAX = do {
        sub p6_native_libc_limits_shrt_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_shrt_max;
    }

    constant USHRT_MAX = do {
        sub p6_native_libc_limits_ushrt_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_ushrt_max;
    }

    constant INT_MIN = do {
        sub p6_native_libc_limits_int_min(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_int_min;
    }

    constant INT_MAX = do {
        sub p6_native_libc_limits_int_max(--> int) is native(CTDLL) { * }
        p6_native_libc_limits_int_max;
    }

    constant UINT_MAX = do {
        sub p6_native_libc_limits_uint_max(--> uint) is native(CTDLL) { * }
        p6_native_libc_limits_uint_max;
    }

    constant LONG_MIN = do {
        sub p6_native_libc_limits_long_min(--> long) is native(CTDLL) { * }
        p6_native_libc_limits_long_min;
    }

    constant LONG_MAX = do {
        sub p6_native_libc_limits_long_max(--> long) is native(CTDLL) { * }
        p6_native_libc_limits_long_max;
    }

    constant ULONG_MAX = do {
        sub p6_native_libc_limits_ulong_max(--> ulong) is native(CTDLL) { * }
        p6_native_libc_limits_ulong_max;
    }

    constant LLONG_MIN = do {
        sub p6_native_libc_limits_llong_min(--> llong) is native(CTDLL) { * }
        p6_native_libc_limits_llong_min;
    }

    constant LLONG_MAX = do {
        sub p6_native_libc_limits_llong_max(--> llong) is native(CTDLL) { * }
        p6_native_libc_limits_llong_max;
    }

    constant ULLONG_MAX = do {
        sub p6_native_libc_limits_ullong_max(--> ullong) is native(CTDLL) { * }
        my \value = p6_native_libc_limits_ullong_max;
        value < 0
            ?? value + 2 ** (sizeof(ullong) * CHAR_BIT) # BUG -- no 64-bit unsigned
            !! value;
    }

    constant limits = %(
        :CHAR_BIT(CHAR_BIT),
        :SCHAR_MIN(SCHAR_MIN),
        :SCHAR_MAX(SCHAR_MAX),
        :UCHAR_MAX(UCHAR_MAX),
        :CHAR_MIN(CHAR_MIN),
        :CHAR_MAX(CHAR_MAX),
        :MB_LEN_MAX(MB_LEN_MAX),
        :SHRT_MIN(SHRT_MIN),
        :SHRT_MAX(SHRT_MAX),
        :USHRT_MAX(USHRT_MAX),
        :INT_MIN(INT_MIN),
        :INT_MAX(INT_MAX),
        :UINT_MAX(UINT_MAX),
        :LONG_MIN(LONG_MIN),
        :LONG_MAX(LONG_MAX),
        :ULONG_MAX(ULONG_MAX),
        :LLONG_MIN(LLONG_MIN),
        :LLONG_MAX(LLONG_MAX),
        :ULLONG_MAX(ULLONG_MAX)
    );

    # <stdio.h>
    class FILE is repr('CPointer') { ... }

    our sub fopen(Str, Str --> FILE) is native(LIBC) { * }
    our sub fclose(FILE --> int) is native(LIBC) { * }
    our sub fflush(FILE --> int) is native(LIBC) { * }
    our sub puts(Str --> int) is native(LIBC) { * }
    our sub fgets(Ptr, int, FILE --> Str) is native(LIBC) { * }
    our sub fread(Ptr, size_t, size_t, FILE --> size_t) is native(LIBC) { * }
    our sub feof(FILE --> int) is native(LIBC) { * }
    our sub fseek(FILE, long, int --> int) is native(LIBC) { * };

    our sub malloc(size_t --> Ptr) is native(LIBC) { * }
    our sub realloc(Ptr, size_t --> Ptr) is native(LIBC) { * }
    our sub calloc(size_t, size_t --> Ptr) is native(LIBC) { * }
    our sub free(Ptr) is native(LIBC) { * }

    our sub memcpy(Ptr, Ptr, size_t --> Ptr) is native(LIBC) { * }
    our sub memmove(Ptr, Ptr, size_t --> Ptr) is native(LIBC) { * }
    our sub memset(Ptr, int, size_t --> Ptr) is native(LIBC) { * }

    our sub memcmp(Ptr, Ptr, size_t --> int) is native(LIBC) { * }

    our sub strlen(Ptr[int8] --> size_t) is native(LIBC) { * }

    our sub system(Str --> int) is native(LIBC) { * }
    our sub exit(int) is native(LIBC) { * }
    our sub abort() is native(LIBC) { * }
    our sub raise(int --> int) is native(LIBC) { * }

    our sub getenv(Str --> Str) is native(LIBC) { * }

    our sub srand(uint) is native(LIBC) { * };
    our sub rand(--> int) is native(LIBC) { * };

    # <time.h>
    constant CLOCKS_PER_SEC = do {
        sub p6_native_libc_time_clocks_per_sec(--> clock_t) is native(CTDLL) { * }
        p6_native_libc_time_clocks_per_sec;
    }

    our sub clock(--> clock_t) is native(LIBC) { * }
    our sub time(Ptr[time_t] --> time_t) is native(LIBC) { * }

    class FILE is Ptr {
        method open(FILE:U: Str \path, Str \mode = 'r') {
            fopen(path, mode)
        }

        method close(FILE:D:) {
            fclose(self) == 0 or fail
        }

        method flush(FILE:D:) {
            fflush(self) == 0 or fail
        }

        method eof(FILE:D:) {
            feof(self) != 0
        }

        method seek(FILE:D: Int \offset, Int \whence) {
            fseek(self, offset, whence) == 0 or fail
        }

        method gets(FILE:D: Ptr() \ptr, int \count) {
            fgets(ptr, count, self) orelse fail
        }
    }
}

sub EXPORT(*@list) {
    Map.new(
        'libc' => TinyCC::Lib::C,
        @list.map({
            when TinyCC::Lib::C::{"&$_"}:exists {
                "&$_" => TinyCC::Lib::C::{"&$_"};
            }

            when TinyCC::Lib::C::{"$_"}:exists {
                "$_" => TinyCC::Lib::C::{"$_"};
            }

            default { die "Unknown identifier '$_'"}
        })
    );
}
