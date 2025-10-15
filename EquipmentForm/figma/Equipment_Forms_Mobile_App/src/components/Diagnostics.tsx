import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Separator } from "./ui/separator";
import { 
  ArrowLeft, 
  Copy, 
  CheckCircle2, 
  AlertTriangle,
  Smartphone,
  Settings,
  Zap
} from "lucide-react";

interface DiagnosticsProps {
  onBack: () => void;
}

export function Diagnostics({ onBack }: DiagnosticsProps) {
  const [copied, setCopied] = useState(false);

  const diagnosticData = {
    ocrEngine: {
      version: "Tesseract.js 4.0.2",
      status: "Ready",
      thresholds: {
        high: 80,
        medium: 60,
        low: 40
      }
    },
    device: {
      platform: navigator.platform,
      userAgent: navigator.userAgent,
      language: navigator.language,
      online: navigator.onLine,
      cookieEnabled: navigator.cookieEnabled,
      touchPoints: navigator.maxTouchPoints || 0
    },
    app: {
      templateVersion: "1.0.0",
      buildDate: "2024-01-15",
      features: {
        preprocessing: true,
        sectionOCR: true,
        offlineMode: true,
        pdfGeneration: true
      }
    },
    permissions: {
      camera: "granted",
      files: "granted",
      share: "available"
    }
  };

  const handleCopyDiagnostics = async () => {
    const diagnosticText = JSON.stringify(diagnosticData, null, 2);
    
    try {
      await navigator.clipboard.writeText(diagnosticText);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      console.error('Failed to copy diagnostics:', error);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status.toLowerCase()) {
      case 'ready':
      case 'granted':
      case 'available':
        return <Badge className="bg-success text-success-foreground text-xs">Ready</Badge>;
      case 'limited':
        return <Badge className="bg-warning text-warning-foreground text-xs">Limited</Badge>;
      case 'denied':
      case 'error':
        return <Badge className="bg-destructive text-destructive-foreground text-xs">Error</Badge>;
      default:
        return <Badge variant="secondary" className="text-xs">{status}</Badge>;
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-primary text-primary-foreground p-4">
        <div className="flex items-center space-x-3">
          <Button
            variant="ghost"
            size="sm"
            onClick={onBack}
            className="text-primary-foreground hover:bg-primary-foreground/10"
          >
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div>
            <h1 className="text-xl">Diagnostics</h1>
            <p className="text-sm opacity-90">System Information</p>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-6">
        {/* OCR Engine Status */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Zap className="w-5 h-5 text-accent" />
                <CardTitle>OCR Engine</CardTitle>
              </div>
              {getStatusBadge(diagnosticData.ocrEngine.status)}
            </div>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <strong>Version:</strong>
                <div className="text-muted-foreground">{diagnosticData.ocrEngine.version}</div>
              </div>
              <div>
                <strong>Status:</strong>
                <div className="text-muted-foreground">{diagnosticData.ocrEngine.status}</div>
              </div>
            </div>
            
            <Separator />
            
            <div>
              <strong>Confidence Thresholds:</strong>
              <div className="mt-2 space-y-1">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">High Confidence:</span>
                  <Badge className="bg-success text-success-foreground text-xs">
                    ≥{diagnosticData.ocrEngine.thresholds.high}%
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Medium Confidence:</span>
                  <Badge className="bg-warning text-warning-foreground text-xs">
                    {diagnosticData.ocrEngine.thresholds.medium}-{diagnosticData.ocrEngine.thresholds.high-1}%
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Low Confidence:</span>
                  <Badge className="bg-destructive text-destructive-foreground text-xs">
                    &lt;{diagnosticData.ocrEngine.thresholds.medium}%
                  </Badge>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Device Information */}
        <Card>
          <CardHeader>
            <div className="flex items-center space-x-2">
              <Smartphone className="w-5 h-5" />
              <CardTitle>Device Information</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="grid grid-cols-1 gap-3">
              <div>
                <strong>Platform:</strong>
                <div className="text-muted-foreground">{diagnosticData.device.platform}</div>
              </div>
              <div>
                <strong>Language:</strong>
                <div className="text-muted-foreground">{diagnosticData.device.language}</div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <strong>Online:</strong>
                  <div className="text-muted-foreground">
                    {diagnosticData.device.online ? 'Yes' : 'No'}
                  </div>
                </div>
                <div>
                  <strong>Touch Points:</strong>
                  <div className="text-muted-foreground">{diagnosticData.device.touchPoints}</div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* App Features */}
        <Card>
          <CardHeader>
            <div className="flex items-center space-x-2">
              <Settings className="w-5 h-5" />
              <CardTitle>App Features</CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <strong>Template Version:</strong>
                <div className="text-muted-foreground">{diagnosticData.app.templateVersion}</div>
              </div>
              <div>
                <strong>Build Date:</strong>
                <div className="text-muted-foreground">{diagnosticData.app.buildDate}</div>
              </div>
            </div>
            
            <Separator />
            
            <div>
              <strong>Available Features:</strong>
              <div className="mt-2 grid grid-cols-2 gap-2">
                {Object.entries(diagnosticData.app.features).map(([feature, enabled]) => (
                  <div key={feature} className="flex items-center justify-between">
                    <span className="text-muted-foreground capitalize">
                      {feature.replace(/([A-Z])/g, ' $1').trim()}:
                    </span>
                    {enabled ? (
                      <CheckCircle2 className="w-4 h-4 text-success" />
                    ) : (
                      <AlertTriangle className="w-4 h-4 text-warning" />
                    )}
                  </div>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Permissions */}
        <Card>
          <CardHeader>
            <CardTitle>Permissions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            {Object.entries(diagnosticData.permissions).map(([permission, status]) => (
              <div key={permission} className="flex items-center justify-between">
                <span className="capitalize">{permission}:</span>
                {getStatusBadge(status)}
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Copy Diagnostics */}
        <Card className="bg-muted/50">
          <CardContent className="pt-6">
            <div className="text-center space-y-4">
              <div>
                <h3 className="font-medium">Export Diagnostics</h3>
                <p className="text-sm text-muted-foreground">
                  Copy diagnostic information for troubleshooting
                </p>
              </div>
              
              <Button 
                onClick={handleCopyDiagnostics}
                variant="outline"
                className="w-full"
              >
                {copied ? (
                  <>
                    <CheckCircle2 className="w-4 h-4 mr-2 text-success" />
                    Copied to Clipboard
                  </>
                ) : (
                  <>
                    <Copy className="w-4 h-4 mr-2" />
                    Copy to Clipboard
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Debug Info */}
        <Card className="bg-muted/50">
          <CardHeader>
            <CardTitle className="text-sm">Debug Information</CardTitle>
          </CardHeader>
          <CardContent className="text-xs text-muted-foreground">
            <div className="space-y-1">
              <div>Session ID: {Math.random().toString(36).substr(2, 9)}</div>
              <div>Timestamp: {new Date().toISOString()}</div>
              <div>Environment: Production</div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}