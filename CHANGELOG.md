## 1.0.0-pre-6
* modify `refreshConfig` to update config after change 
* modify `SimpleApiRequest`

## 1.0.0-pre-5
* modify default headers to options

## 1.0.0-pre-4
* fix return response when status code not success

## 1.0.0-pre-3
* modify `run` method use Either `ApiRequestAction`
* modify `ApiRequestException` to handle api server errors

## 1.0.0-pre-2
* modify `listFormat` global option in `ApiRequestOptions`

## 1.0.0-pre-1
* modify `onError` global error handler in `ApiRequestOptions`

## 0.8.5
* modify `ApiRequestError` to to dynamic error
* modify `subscribe` to call `execute` or `onQueue`

## 0.8.0
* add `ApiRequestPerformance` to extract performance report
* convert events to `getter`, `setter` to access its from any where

## 0.7.2
* modify `ApiRequestError` by use try catch

## 0.7.1
* update documentation

## 0.7.0
* add `ApiRequestAction` for simple api request don't need to `ApiRequest` class
* rename `onChnage` to `subscribe`
* merge `defaultQueryParameters` with old instance
* merge `interceptors` with old instance
* add more to `ApiRequestOptions`:
    * connectionTimeOut
    * interceptors
    * enableLog

## 0.5.3
* fix typing error

## 0.5.2
* modify token type api request options

## 0.5.1
* fix execute return type

## 0.5.0
* you can access stream if action run onQueue
* fix run package in web
* use dio instance
* dispose action after success or error

## 0.1.2
* fix run in mobile
* reverse support web

## 0.1.1
* fix support web

## 0.1.0
* refactor `RequestAction`
* add `onQueue`
* listen to action `onInit`, `onStart`, `onSuccess`, `onError`
* add `ApiRequestError`
* add `onChange` to subscribe to stream

## 0.0.6
* add Token to Header by Interceptors

## 0.0.5
* add contentDataType for request
* convert `ApiRequest` to `mixin`

## 0.0.4
* add dynamic path
  
## 0.0.3+1
* update change log

## 0.0.3
* improve document
* add more example

## 0.0.2
* first release for flutter api request as action

## 0.0.1
* TODO: Describe initial release.
