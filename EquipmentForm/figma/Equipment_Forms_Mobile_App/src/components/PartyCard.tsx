import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Button } from "./ui/button";
import { Switch } from "./ui/switch";
import { Badge } from "./ui/badge";
import { 
  Camera, 
  FileText, 
  Keyboard, 
  Scan, 
  Copy, 
  Check, 
  AlertCircle,
  Zap
} from "lucide-react";

interface PartyMember {
  name: string;
  department: string;
  email: string;
  confidence?: {
    name: number;
    department: number;
    email: number;
  };
}

interface PartyCardProps {
  title: string;
  member: PartyMember;
  onUpdate: (member: PartyMember) => void;
  canCopyFrom?: PartyMember;
  onCopyFrom?: () => void;
  isCopied?: boolean;
  onFieldCapture?: (field: 'name' | 'department' | 'email') => void;
  onSectionOCR?: () => void;
}

export function PartyCard({ 
  title, 
  member, 
  onUpdate, 
  canCopyFrom, 
  onCopyFrom, 
  isCopied,
  onFieldCapture,
  onSectionOCR 
}: PartyCardProps) {
  const [isLocked, setIsLocked] = useState(isCopied || false);

  const getConfidenceColor = (confidence?: number) => {
    if (!confidence) return "";
    if (confidence >= 0.8) return "bg-[rgb(75,160,70)]";
    if (confidence >= 0.6) return "bg-[rgb(250,150,30)]";
    return "bg-[rgb(100,20,15)]";
  };

  const handleCopyFrom = () => {
    if (canCopyFrom && onCopyFrom) {
      onCopyFrom();
      setIsLocked(true);
    }
  };

  const handleUnlock = () => {
    setIsLocked(false);
  };

  const updateField = (field: keyof PartyMember, value: string) => {
    if (!isLocked) {
      onUpdate({ ...member, [field]: value });
    }
  };

  return (
    <Card className={`transition-all duration-200 ${isLocked ? 'bg-muted/50 border-[rgb(75,160,70)]' : ''}`}>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">{title}</CardTitle>
          {onSectionOCR && (
            <Button
              variant="outline"
              size="sm"
              onClick={onSectionOCR}
              className="text-[rgb(255,190,20)] border-[rgb(255,190,20)] hover:bg-[rgb(255,190,20)] hover:text-[rgb(16,48,87)]"
            >
              <Zap className="w-4 h-4 mr-2" />
              Section OCR
            </Button>
          )}
        </div>
        
        {canCopyFrom && (
          <div className="flex items-center space-x-2">
            <Switch
              checked={isLocked}
              onCheckedChange={(checked) => {
                if (checked) {
                  handleCopyFrom();
                } else {
                  handleUnlock();
                }
              }}
            />
            <Label className="text-sm">Same as Requested By</Label>
            {isLocked && (
              <Badge variant="secondary" className="text-xs">
                <Check className="w-3 h-3 mr-1" />
                Linked
              </Badge>
            )}
          </div>
        )}
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Name Field */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label>Name</Label>
            <div className="flex items-center space-x-1">
              {member.confidence?.name && (
                <Badge 
                  variant="outline" 
                  className={`text-xs ${getConfidenceColor(member.confidence.name)} text-white border-0`}
                >
                  {Math.round(member.confidence.name * 100)}%
                </Badge>
              )}
              {onFieldCapture && !isLocked && (
                <div className="flex space-x-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onFieldCapture('name')}
                    className="h-8 w-8 p-0"
                  >
                    <Camera className="w-4 h-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onFieldCapture('name')}
                    className="h-8 w-8 p-0"
                  >
                    <FileText className="w-4 h-4" />
                  </Button>
                </div>
              )}
            </div>
          </div>
          <Input
            value={member.name}
            onChange={(e) => updateField('name', e.target.value)}
            placeholder="Enter full name"
            disabled={isLocked}
            className={isLocked ? 'bg-muted' : ''}
          />
        </div>

        {/* Department Field */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label>Department</Label>
            <div className="flex items-center space-x-1">
              {member.confidence?.department && (
                <Badge 
                  variant="outline" 
                  className={`text-xs ${getConfidenceColor(member.confidence.department)} text-white border-0`}
                >
                  {Math.round(member.confidence.department * 100)}%
                </Badge>
              )}
              {onFieldCapture && !isLocked && (
                <div className="flex space-x-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onFieldCapture('department')}
                    className="h-8 w-8 p-0"
                  >
                    <Camera className="w-4 h-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onFieldCapture('department')}
                    className="h-8 w-8 p-0"
                  >
                    <FileText className="w-4 h-4" />
                  </Button>
                </div>
              )}
            </div>
          </div>
          <Input
            value={member.department}
            onChange={(e) => updateField('department', e.target.value)}
            placeholder="e.g., IT Support, Operations"
            disabled={isLocked}
            className={isLocked ? 'bg-muted' : ''}
          />
        </div>

        {/* Email Field */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label>Email</Label>
            <div className="flex items-center space-x-1">
              {member.confidence?.email && (
                <Badge 
                  variant="outline" 
                  className={`text-xs ${getConfidenceColor(member.confidence.email)} text-white border-0`}
                >
                  {Math.round(member.confidence.email * 100)}%
                </Badge>
              )}
              {onFieldCapture && !isLocked && (
                <div className="flex space-x-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onFieldCapture('email')}
                    className="h-8 w-8 p-0"
                  >
                    <Camera className="w-4 h-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onFieldCapture('email')}
                    className="h-8 w-8 p-0"
                  >
                    <FileText className="w-4 h-4" />
                  </Button>
                </div>
              )}
            </div>
          </div>
          <Input
            value={member.email}
            onChange={(e) => updateField('email', e.target.value)}
            placeholder="email@tullowoil.com"
            type="email"
            disabled={isLocked}
            className={isLocked ? 'bg-muted' : ''}
          />
        </div>
      </CardContent>
    </Card>
  );
}