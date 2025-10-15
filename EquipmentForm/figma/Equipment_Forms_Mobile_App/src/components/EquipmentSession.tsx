import { useState } from "react";
import { Stepper } from "./Stepper";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Badge } from "./ui/badge";
import { Switch } from "./ui/switch";
import { ArrowLeft, ArrowRight, Laptop, Smartphone, Plus, X, Camera } from "lucide-react";

interface Equipment {
  type: 'laptop' | 'phone' | 'accessory';
  make?: string;
  model?: string;
  assetTag?: string;
  serviceTag?: string;
  serial?: string;
  imei?: string;
  warrantyExpiry?: string;
  name?: string; // For accessories
}

interface EquipmentData {
  devices: Array<{
    id: string;
    type: 'laptop' | 'phone' | 'accessory';
    make?: string;
    model?: string;
    assetTag?: string;
    serviceTag?: string;
    imei?: string;
    serial?: string;
    warrantyExpiry?: string;
    name?: string; // for accessories
  }>;
}

interface EquipmentSessionProps {
  formType: 'received' | 'returned' | 'replaced';
  onComplete: (equipmentData: EquipmentData) => void;
  onBack: () => void;
  initialData?: EquipmentData;
}

const WORKFLOW_STEPS = [
  { id: 1, label: "Party", description: "People involved" },
  { id: 2, label: "Equipment", description: "Device details" },
  { id: 3, label: "Workflow", description: "Dates & process" },
  { id: 4, label: "Review", description: "Verify & export" }
];

const PHONE_MODELS = [
  "iPhone 11",
  "iPhone 11 Pro",
  "iPhone 11 Pro Max",
  "iPhone 12",
  "iPhone 12 Pro",
  "iPhone 12 Pro Max",
  "iPhone 13",
  "iPhone 13 Pro",
  "iPhone 13 Pro Max",
  "iPhone 14",
  "iPhone 14 Pro",
  "iPhone 14 Pro Max",
  "iPhone 15",
  "iPhone 15 Pro",
  "iPhone 15 Pro Max"
];

const ACCESSORY_SUGGESTIONS: Record<string, string[]> = {
  laptop: ["Adapter", "Bag", "Mouse"],
  phone: ["Charger", "Case", "Screen Protector"]
};

export function EquipmentSession({ formType, onComplete, onBack, initialData }: EquipmentSessionProps) {
  const [primaryEquipment, setPrimaryEquipment] = useState<Equipment>(() => {
    const primary = initialData?.devices.find(d => d.type !== 'accessory');
    return primary || {
      type: 'laptop',
      make: '',
      model: '',
      assetTag: '',
      serviceTag: '',
      warrantyExpiry: ''
    };
  });

  const [accessories, setAccessories] = useState<Equipment[]>(() => {
    return initialData?.devices.filter(d => d.type === 'accessory') || [];
  });
  const [improveLegibility, setImproveLegibility] = useState(false);

  const getAssetPrefix = (type: Equipment['type']) => {
    const prefixes = {
      laptop: `ACC-LT-`, // Default location, could be made dynamic
      phone: `ACC-MB-`,
      accessory: ''
    };
    return prefixes[type];
  };

  const updatePrimaryEquipment = (updates: Partial<Equipment>) => {
    setPrimaryEquipment(prev => ({ ...prev, ...updates }));
  };

  const addAccessory = (name: string) => {
    setAccessories(prev => [...prev, { type: 'accessory', name }]);
  };

  const removeAccessory = (index: number) => {
    setAccessories(prev => prev.filter((_, i) => i !== index));
  };

  const renderRowSimulator = () => {
    const leftColumn = [
      `${primaryEquipment.make || ''} ${primaryEquipment.model || ''}`.trim() || 'No device selected',
      ...accessories.map(acc => `WITH ${acc.name?.toUpperCase() || ''}`)
    ];

    const rightColumns = [];
    
    if (primaryEquipment.type === 'laptop') {
      if (primaryEquipment.assetTag) rightColumns.push(primaryEquipment.assetTag);
      if (primaryEquipment.serviceTag) rightColumns.push(primaryEquipment.serviceTag);
      if (primaryEquipment.warrantyExpiry) rightColumns.push(primaryEquipment.warrantyExpiry);
    } else if (primaryEquipment.type === 'phone') {
      if (primaryEquipment.imei) rightColumns.push(primaryEquipment.imei);
      if (primaryEquipment.serial) rightColumns.push(primaryEquipment.serial);
      if (primaryEquipment.assetTag) rightColumns.push(primaryEquipment.assetTag);
    }

    return (
      <Card className="bg-muted/50">
        <CardHeader>
          <CardTitle className="text-sm">Row Simulator Preview</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              {leftColumn.map((line, index) => (
                <div key={index} className={index === 0 ? '' : 'text-muted-foreground'}>
                  {line}
                </div>
              ))}
            </div>
            <div className="space-y-1">
              {rightColumns.map((col, index) => (
                <div key={index}>{col}</div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>
    );
  };

  const isValid = () => {
    if (primaryEquipment.type === 'laptop') {
      return primaryEquipment.make && primaryEquipment.model && 
             primaryEquipment.assetTag && primaryEquipment.serviceTag;
    } else if (primaryEquipment.type === 'phone') {
      return primaryEquipment.model && primaryEquipment.imei;
    }
    return false;
  };

  const handleNext = () => {
    if (isValid()) {
      const devices = [
        { ...primaryEquipment, id: 'primary-' + Date.now() },
        ...accessories.map((acc, index) => ({ ...acc, id: 'accessory-' + index + '-' + Date.now() }))
      ];
      
      onComplete({
        devices
      });
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
            <h1 className="text-xl">Equipment {formType}</h1>
            <p className="text-sm opacity-90">Device Details</p>
          </div>
        </div>
      </div>

      {/* Stepper */}
      <Stepper currentStep={2} steps={WORKFLOW_STEPS} />

      {/* Content */}
      <div className="p-4 space-y-6 pb-20">
        {/* Device Type Selector */}
        <Card>
          <CardHeader>
            <CardTitle>Device Type</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex space-x-2">
              <Button
                variant={primaryEquipment.type === 'laptop' ? 'default' : 'outline'}
                onClick={() => updatePrimaryEquipment({ type: 'laptop' })}
                className="flex-1"
              >
                <Laptop className="w-4 h-4 mr-2" />
                Laptop
              </Button>
              <Button
                variant={primaryEquipment.type === 'phone' ? 'default' : 'outline'}
                onClick={() => updatePrimaryEquipment({ type: 'phone' })}
                className="flex-1"
              >
                <Smartphone className="w-4 h-4 mr-2" />
                Phone
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Primary Equipment Details */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>
                {primaryEquipment.type === 'laptop' ? 'Laptop' : 'Phone'} Details
              </CardTitle>
              <Button variant="outline" size="sm">
                <Camera className="w-4 h-4 mr-2" />
                Capture
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {primaryEquipment.type === 'laptop' && (
              <>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Make</Label>
                    <Input
                      placeholder="e.g., Dell, HP, Lenovo"
                      value={primaryEquipment.make || ''}
                      onChange={(e) => updatePrimaryEquipment({ make: e.target.value })}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>Model</Label>
                    <Input
                      placeholder="e.g., Latitude 5520"
                      value={primaryEquipment.model || ''}
                      onChange={(e) => updatePrimaryEquipment({ model: e.target.value })}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Asset Tag</Label>
                  <div className="flex">
                    <Badge variant="secondary" className="rounded-r-none">
                      {getAssetPrefix('laptop')}
                    </Badge>
                    <Input
                      placeholder="12345"
                      value={primaryEquipment.assetTag?.replace(getAssetPrefix('laptop'), '') || ''}
                      onChange={(e) => updatePrimaryEquipment({ 
                        assetTag: getAssetPrefix('laptop') + e.target.value 
                      })}
                      className="rounded-l-none border-l-0"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Service Tag *</Label>
                  <Input
                    placeholder="Service tag (required)"
                    value={primaryEquipment.serviceTag || ''}
                    onChange={(e) => updatePrimaryEquipment({ serviceTag: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label>Warranty Expiry</Label>
                  <Input
                    type="date"
                    value={primaryEquipment.warrantyExpiry || ''}
                    onChange={(e) => updatePrimaryEquipment({ warrantyExpiry: e.target.value })}
                  />
                </div>
              </>
            )}

            {primaryEquipment.type === 'phone' && (
              <>
                <div className="space-y-2">
                  <Label>Model *</Label>
                  <Select
                    value={primaryEquipment.model || ''}
                    onValueChange={(value) => updatePrimaryEquipment({ model: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select iPhone model" />
                    </SelectTrigger>
                    <SelectContent>
                      {PHONE_MODELS.map(model => (
                        <SelectItem key={model} value={model}>{model}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>IMEI *</Label>
                  <Input
                    placeholder="15-digit IMEI number"
                    value={primaryEquipment.imei || ''}
                    onChange={(e) => {
                      const value = e.target.value.replace(/\D/g, '').slice(0, 15);
                      updatePrimaryEquipment({ imei: value });
                    }}
                    maxLength={15}
                  />
                  <p className="text-xs text-muted-foreground">
                    Enter 15 digits. Current: {(primaryEquipment.imei || '').length}/15
                  </p>
                </div>

                <div className="space-y-2">
                  <Label>Serial Number</Label>
                  <Input
                    placeholder="Optional serial number"
                    value={primaryEquipment.serial || ''}
                    onChange={(e) => updatePrimaryEquipment({ serial: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label>Asset Tag (Optional)</Label>
                  <div className="flex">
                    <Badge variant="secondary" className="rounded-r-none">
                      {getAssetPrefix('phone')}
                    </Badge>
                    <Input
                      placeholder="12345"
                      value={primaryEquipment.assetTag?.replace(getAssetPrefix('phone'), '') || ''}
                      onChange={(e) => updatePrimaryEquipment({ 
                        assetTag: getAssetPrefix('phone') + e.target.value 
                      })}
                      className="rounded-l-none border-l-0"
                    />
                  </div>
                </div>
              </>
            )}

            {/* Image Improvement Toggle */}
            <div className="flex items-center space-x-2 pt-4 border-t">
              <Switch
                checked={improveLegibility}
                onCheckedChange={setImproveLegibility}
              />
              <Label>Improve Legibility</Label>
              <Badge variant="outline" className="text-xs">
                Preprocessing
              </Badge>
            </div>
          </CardContent>
        </Card>

        {/* Accessory Suggestions */}
        <Card>
          <CardHeader>
            <CardTitle>Accessories</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex flex-wrap gap-2">
                {ACCESSORY_SUGGESTIONS[primaryEquipment.type]?.map(accessory => (
                  <Button
                    key={accessory}
                    variant="outline"
                    size="sm"
                    onClick={() => addAccessory(accessory)}
                    disabled={accessories.some(acc => acc.name === accessory)}
                  >
                    <Plus className="w-3 h-3 mr-1" />
                    {accessory}
                  </Button>
                ))}
              </div>

              {accessories.length > 0 && (
                <div className="space-y-2">
                  <Label>Added Accessories</Label>
                  <div className="flex flex-wrap gap-2">
                    {accessories.map((accessory, index) => (
                      <Badge key={index} variant="secondary" className="text-sm">
                        {accessory.name}
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => removeAccessory(index)}
                          className="ml-1 h-4 w-4 p-0 hover:bg-destructive hover:text-destructive-foreground"
                        >
                          <X className="w-3 h-3" />
                        </Button>
                      </Badge>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Row Simulator */}
        {renderRowSimulator()}
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-background border-t border-border">
        <Button
          onClick={handleNext}
          disabled={!isValid()}
          className="w-full h-12"
        >
          Next: Workflow
          <ArrowRight className="w-4 h-4 ml-2" />
        </Button>
      </div>
    </div>
  );
}