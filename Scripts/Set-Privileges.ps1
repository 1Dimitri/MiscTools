# From https://hinchley.net/articles/create-a-new-registry-hive-using-powershell/

Add-Type -TypeDefinition @'
using System;  
using System.Text;  
using System.Runtime.InteropServices;  
using Microsoft.Win32; 

namespace Privileges {  
  public class TokenPrivileges {
    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
    public static extern int OpenProcessToken(int ProcessHandle, int DesiredAccess, ref int tokenhandle);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern int GetCurrentProcess();

    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
    public static extern int LookupPrivilegeValue(string lpsystemname, string lpname, [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);

    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
    public static extern int AdjustTokenPrivileges(int tokenhandle, int disableprivs, [MarshalAs(UnmanagedType.Struct)] ref TOKEN_PRIVILEGE Newstate, int bufferlength, int PreivousState, int Returnlength);

    public const int TOKEN_ASSIGN_PRIMARY = 0x00000001;
    public const int TOKEN_DUPLICATE = 0x00000002;
    public const int TOKEN_IMPERSONATE = 0x00000004;
    public const int TOKEN_QUERY = 0x00000008;
    public const int TOKEN_QUERY_SOURCE = 0x00000010;
    public const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    public const int TOKEN_ADJUST_GROUPS = 0x00000040;
    public const int TOKEN_ADJUST_DEFAULT = 0x00000080;

    public const UInt32 SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x00000001;
    public const UInt32 SE_PRIVILEGE_ENABLED = 0x00000002;
    public const UInt32 SE_PRIVILEGE_REMOVED = 0x00000004;
    public const UInt32 SE_PRIVILEGE_USED_FOR_ACCESS = 0x80000000;

    public static void EnablePrivilege(string privilege) {
      var token = 0;

      var TP = new TOKEN_PRIVILEGE();
      var LD = new LUID();

      OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref token);
      LookupPrivilegeValue(null, privilege, ref LD);
      TP.PrivilegeCount = 1;

      var luidAndAtt = new LUID_AND_ATTRIBUTES {Attributes = SE_PRIVILEGE_ENABLED, Luid = LD};
      TP.Privilege = luidAndAtt;

      AdjustTokenPrivileges(token, 0, ref TP, 1024, 0, 0);
    }

    public static void DisablePrivilege(string privilege) {
      var token = 0;

      var TP = new TOKEN_PRIVILEGE();
      var LD = new LUID();

      OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref token);
      LookupPrivilegeValue(null, privilege, ref LD);
      TP.PrivilegeCount = 1;

      var luidAndAtt = new LUID_AND_ATTRIBUTES {Luid = LD};
      TP.Privilege = luidAndAtt;

      AdjustTokenPrivileges(token, 0, ref TP, 1024, 0, 0);
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct LUID {
      internal uint LowPart;
      internal uint HighPart;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct LUID_AND_ATTRIBUTES {
      internal LUID Luid;
      internal uint Attributes;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct TOKEN_PRIVILEGE {
      internal uint PrivilegeCount;
      internal LUID_AND_ATTRIBUTES Privilege;
    }
  }
}
'@

# Examples:
# [Privileges.TokenPrivileges]::EnablePrivilege('SeBackupPrivilege') 

# [Privileges.TokenPrivileges]::DisablePrivilege('SeBackupPrivilege') 