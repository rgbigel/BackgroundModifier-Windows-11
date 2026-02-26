<# ============================================================================================
  Path:       D:\OneDrive\Git_Repositories\PS\BackgroundModifier\Source\Modules
  Module:     TranscriptTools.psm1
  Version:    1.000
  Author:     Rolf Bercht

  Purpose:
      Provides helper functions for starting and stopping transcripts.
============================================================================================ #>

function Start-TraceTranscript {
    param(
        [string]$Path
    )

    Start-Transcript -Path $Path -Append | Out-Null
}

function Stop-TraceTranscript {
    Stop-Transcript | Out-Null
}
