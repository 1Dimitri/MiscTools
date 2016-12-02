FOR /F "skip=2 tokens=2-7 delims=," %%A IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:csv') DO (
	SET Today=%%F%%D%%A
	SET Now=%%B%%C%%E
)