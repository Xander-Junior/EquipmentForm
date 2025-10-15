import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Button } from "./ui/button";
import { User, MapPin, Building } from "lucide-react";

interface ProfileData {
  name: string;
  department: string;
  defaultLocation: string;
}

interface ProfileSetupProps {
  onComplete: (profile: ProfileData) => void;
  initialData?: ProfileData;
}

export function ProfileSetup({ onComplete, initialData }: ProfileSetupProps) {
  const [profile, setProfile] = useState<ProfileData>({
    name: initialData?.name || "",
    department: initialData?.department || "",
    defaultLocation: initialData?.defaultLocation || ""
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (profile.name && profile.department && profile.defaultLocation) {
      onComplete(profile);
    }
  };

  const isValid = profile.name && profile.department && profile.defaultLocation;

  return (
    <div className="min-h-screen bg-background p-4 flex items-center justify-center">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center space-y-2">
          <div className="w-16 h-16 bg-primary rounded-full flex items-center justify-center mx-auto">
            <User className="w-8 h-8 text-primary-foreground" />
          </div>
          <CardTitle>Setup Your Profile</CardTitle>
          <CardDescription>
            This information will pre-fill forms and help track your submissions
          </CardDescription>
        </CardHeader>
        
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="name">Your Name</Label>
              <Input
                id="name"
                placeholder="Enter your full name"
                value={profile.name}
                onChange={(e) => setProfile(prev => ({ ...prev, name: e.target.value }))}
                className="h-12"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="department">Department</Label>
              <Input
                id="department"
                placeholder="e.g., IT Support, Operations"
                value={profile.department}
                onChange={(e) => setProfile(prev => ({ ...prev, department: e.target.value }))}
                className="h-12"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="location">Default Location</Label>
              <Select
                value={profile.defaultLocation}
                onValueChange={(value) => setProfile(prev => ({ ...prev, defaultLocation: value }))}
              >
                <SelectTrigger className="h-12">
                  <SelectValue placeholder="Select your primary location" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ACC">Accra (ACC)</SelectItem>
                  <SelectItem value="TAK">Takoradi (TAK)</SelectItem>
                  <SelectItem value="LON">London (LON)</SelectItem>
                  <SelectItem value="ABJ">Abidjan (ABJ)</SelectItem>
                  <SelectItem value="DAR">Dar es Salaam (DAR)</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <Button 
              type="submit" 
              className="w-full h-12"
              disabled={!isValid}
            >
              Continue to Home
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}