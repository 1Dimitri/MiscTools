Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace Registry {
  public class Utils {
    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern int RegCloseKey(UIntPtr hKey);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern int RegOpenKeyEx(UIntPtr hKey, string subKey, int ulOptions, int samDesired, out UIntPtr hkResult);

    [DllImport("advapi32.dll", SetLastError=true, CharSet = CharSet.Unicode)]
    private static extern uint RegSaveKey(UIntPtr hKey, string lpFile, IntPtr lpSecurityAttributes);

    private static int KEY_READ = 131097;
    private static UIntPtr HKEY_LOCAL_MACHINE = new UIntPtr(0x80000002u);

    public static uint SaveKey(string key, string path) {
      UIntPtr hKey = UIntPtr.Zero;
      RegOpenKeyEx(HKEY_LOCAL_MACHINE, key, 0, KEY_READ, out hKey);
      uint result = RegSaveKey(hKey, path, IntPtr.Zero);
      RegCloseKey(hKey);
      return result;
    }
  }
}
'@