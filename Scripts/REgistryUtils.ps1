Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace Registry {

   public enum  HKEY : uint { HKEY_LOCAL_MACHINE = 0x80000002u, HKEY_USERS = 0x80000003u };
   
  public class Utils  {
  	

	[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern Int32 RegLoadKey(uint hKey, string lpSubKey, string lpFile);

	[DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern Int32 RegUnLoadKey(uint hKey, string lpSubKey);
	

    }
	
	# needs [Privileges.TokenPrivileges]::EnablePrivilege('SeRestorePrivilege') 
	public static int LoadKey(HKEY key,string subkey, string path) {
	 // UIntPtr hkey =  new UIntPtr(key);
	  int result = RegLoadKey((uint)key,subkey,path);
	  return result;
	}
	
	public static int UnloadKey(HKEY key,string subkey) {
	  int result = RegUnLoadKey((uint)key,subkey);
	  return result;
	}
	
	
	
  }
}
'@