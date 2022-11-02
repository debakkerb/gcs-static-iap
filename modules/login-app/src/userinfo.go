/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	compute "cloud.google.com/go/compute/apiv1"
	"context"
	"fmt"
	"google.golang.org/api/idtoken"
	computepb "google.golang.org/genproto/googleapis/cloud/compute/v1"
	"log"
	"net/http"
	"strconv"
)

type UserInfo struct {
	UserID    string
	UserEmail string
}

func retrieveUserDetails(r *http.Request) (*UserInfo, error) {
	ctx := context.Background()
	serviceId, err := getServiceId(&ctx, PROJECT_ID)
	if err != nil {
		log.Fatal(err)
	}

	payload, err := validateJWT(r, &ctx, serviceId)
	if err != nil {
		log.Fatal(err)
	}

	email := payload.Claims["email"]
	identity := payload.Claims["sub"]

	return &UserInfo{
		UserID:    fmt.Sprint(identity),
		UserEmail: fmt.Sprint(email),
	}, nil
}

func validateJWT(r *http.Request, ctx *context.Context, backendServiceId uint64) (*idtoken.Payload, error) {
	jwtAssertion := r.Header.Get("x-goog-iap-jwt-assertion")

	audience := fmt.Sprintf("/projects/%s/global/backendServices/%s", PROJECT_NUMBER, strconv.FormatUint(backendServiceId, 10))
	payload, err := idtoken.Validate(*ctx, jwtAssertion, audience)

	if err != nil {
		return nil, err
	}

	return payload, nil
}

func getServiceId(ctx *context.Context, projectID string) (uint64, error) {
	c, err := compute.NewBackendServicesRESTClient(*ctx)
	if err != nil {
		return 0, err
	}
	defer c.Close()

	req := &computepb.GetBackendServiceRequest{
		Project:        PROJECT_ID,
		BackendService: BACKEND_SERVICE_NAME,
	}

	resp, err := c.Get(*ctx, req)
	if err != nil {
		return 0, err
	}

	return *resp.Id, nil
}
