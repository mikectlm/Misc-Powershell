Param(
[string]$input_file,
[string]$output_file
);

add-type @"
public struct Condition {
   public string Name;
   public string Odate;
   public string Sign;
}
"@

#$input_file = "C:\Users\mbobbato\Documents\Work\Amex\amex_Conv_V3\amex_Conv_V3.xml";
#$output_file = "C:\Users\mbobbato\Documents\Work\Amex\amex_Conv_V3\amex_Conv_V4.xml";

$ErrorActionPreference = "Stop"

#$scriptPath = Split-Path -LiteralPath $(if ($PSVersionTable.PSVersion.Major -ge 3) { $PSCommandPath } else { & { $MyInvocation.ScriptName } })

Function ConvertCondition($xn)
{
    $sFromJob = $xn.JOBNAME;
    
    
    $conds = @(); 
    
    $iCount = 0;
    
    $xn_outconds = $xn.SelectNodes('OUTCOND');    

    #Create Conditions list

    
    foreach ($outcond in $xn_outconds)
    {      
        
        if ($outcond.SIGN -eq 'ADD')
        {
            $cond_new = new-Object -TypeName Condition;
            $cond_new.Odate = $outcond.ODATE;
            $cond_new.Sign = $outcond.SIGN;
            $cond_new.Name = $outcond.NAME;
            $conds += $cond_new;       
        }
    }
    
    

    foreach ($c in $conds)
    {     
        $xn_inconds = $xd.SelectNodes('//INCOND[@NAME="' + $c.Name +'"]');
        
        #Log OUTCOND reference that doesn't change due to no INCOND

        
        foreach ($xnToJobCond in $xn_inconds)
        {    
            $xnToJob = $xnToJobCond.ParentNode;
            
            $sToJob = $xnToJob.JOBNAME;

            $sCond = $sFromJob + "-TO-" + $sToJob;

            #Job INCOND has change
            $xnToJobCond.NAME = $sCond;

            #Need to add OUTCOND to original
            #Need to test adding the outcond, may exist already
            
            if (!$xn.SelectSingleNode('OUTCOND[@NAME="' + $sCond + '"]'))
            {
                $xnCond = $xd.CreateElement('OUTCOND');
                $xaSign = $xd.CreateAttribute('SIGN');
                $xaSign.Value = 'ADD';
                $xaCond = $xd.CreateAttribute('NAME');
                $xaCond.Value = $sCond;
                $xaODate = $xd.CreateAttribute('ODATE');
                $xaODate.Value = 'ODAT';
                $redir = $xnCond.Attributes.Append($xaSign);
                $redir = $xnCond.Attributes.Append($xaCond);
                $redir = $xnCond.Attributes.Append($xaODate);
                $xn.InsertAfter($xnCond, $xn.SelectSingleNode('OUTCOND[@NAME="' + $c.Name + '"]'));

                #sLog.AppendLine(sFromJob + " NEW OUT COND " + sCond + " to IN COND on " + sToJob);
                
                #REMOVE DEL OUT CONDITION FROM TO JOB
                #$xnToJob.SelectSingleNode('OUTCOND[@NAME="' + $c.Name + '"]');
        
                if ($xnToJob.SelectSingleNode('OUTCOND[@NAME="' + $c.Name + '" and @SIGN="DEL"]'))
                {
                    $redir = $xnToJob.RemoveChild($xnToJob.SelectSingleNode('OUTCOND[@NAME="' + $c.Name + '" and @SIGN="DEL"]'));
                }
            }

        }
        #REMOVE ADD OUT CONDITION FROM Current Job
        $redir = $xn.RemoveChild($xn.SelectSingleNode('OUTCOND[@NAME="' + $c.Name + '"]'));
        
        
        #sLog.AppendLine(sFromJob + " REMOVED " + c.Name);
        
    }
    
}


Function AddMinusConds($xn)
{

    $xn_inconds = $xn.SelectNodes('INCOND');
    
    foreach ($xnIncond in $xn_inconds)
    {
        $sCondition = $xnIncond.Name;
        
        $xnOutcond = $xn.SelectSingleNode('OUTCOND[@NAME="' + $sCondition + '"]');
        #if corresponding out condition is not found, add it 
        if (!$xnOutcond)
        {
            $xnCond = $xd.CreateElement('OUTCOND');
            $xaSign = $xd.CreateAttribute('SIGN');
            $xaSign.Value = 'DEL';
            $xaCond = $xd.CreateAttribute('NAME');
            $xaCond.Value = $sCondition;
            $xaODate = $xd.CreateAttribute('ODATE');
            $xaODate.Value = 'ODAT';
            $redir = $xnCond.Attributes.Append($xaSign);
            $redir = $xnCond.Attributes.Append($xaCond);
            $redir = $xnCond.Attributes.Append($xaODate);
            $xn.InsertAfter($xnCond, $xnIncond);                                              
        }
    }          
}


$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try
{
    
    $xd = new-Object System.Xml.XmlDocument;
    $xd.Load($input_file);
    $xn_jobs = $xd.SelectNodes('//JOB');
    $xn_tables = $xd.SelectNodes('//SMART_TABLE');
    
    foreach ($xn_job in $xn_jobs)
    {
        ConvertCondition $xn_job;
    }
    
    foreach ($xn_table in $xn_tables)
    {
        ConvertCondition $xn_table;
    }
    
    foreach ($xn_job in $xn_jobs)
    {
        AddMinusConds $xn_job;
    }
    
    foreach ($xn_table in $xn_tables)
    {
        AddMinusConds $xn_table;
    }
    
    $xd.Save($output_file);
	
}
finally
{
    Write-Host "Done!"
    Write-Host "Time to complete: $($stopwatch.Elapsed)"
}

