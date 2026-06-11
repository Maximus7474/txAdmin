import { Route, Switch } from "wouter";
import Login from "../pages/auth/Login";
import CfxreCallback from "../pages/auth/CfxreCallback";
import AddMasterPin from "../pages/auth/AddMasterPin";
import AddMasterCallback from "../pages/auth/AddMasterCallback";
import { Card } from "../components/ui/card";
import { AuthError } from "@/pages/auth/errors";

function AuthContentWrapper({ children }: { children: React.ReactNode }) {
    return (
        <div className="text-center">
            {children}
        </div>
    );
}


export default function AuthShell() {
    return (
        <div className="min-h-screen flex items-center justify-center bg-[url('https://parisinterceptor.com/wp-content/uploads/2026/05/C78A2989-37E8-44B2-BB88-03E170DF95FF.png')] bg-cover bg-center bg-no-repeat overflow-hidden">
            <div className="w-full min-w-[20rem] xs:max-w-[25rem] my-4 xs:mx-4">
                <Card className="min-h-80 mt-4 xs:mt-8 mb-4 flex items-center justify-center bg-card/40 rounded-none xs:rounded-lg">
                    <Switch>
                        <Route path="/login">
                            <Login />
                        </Route>
                        <Route path="/login/callback">
                            <AuthContentWrapper>
                                <CfxreCallback />
                            </AuthContentWrapper>
                        </Route>
                        <Route path="/addMaster/pin">
                            <AuthContentWrapper>
                                <AddMasterPin />
                            </AuthContentWrapper>
                        </Route>
                        <Route path="/addMaster/callback">
                            <AuthContentWrapper>
                                <AddMasterCallback />
                            </AuthContentWrapper>
                        </Route>
                        <Route path="/:fullPath*">
                            <AuthContentWrapper>
                                <AuthError
                                    error={{
                                        errorTitle: '404 | Not Found',
                                        errorMessage: 'Something went wrong.',
                                    }}
                                />
                            </AuthContentWrapper>
                        </Route>
                    </Switch>
                </Card>
            </div>
        </div>
    );
}
