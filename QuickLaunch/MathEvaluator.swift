//
//  MathEvaluator.swift
//  QuickLaunch
//
//  Created by Benjamin Eccles on 9/23/26.
//


import Foundation

/// Tiny recursive-descent math parser. No subprocesses, no NSExpression exceptions —
/// invalid or partial input (like "2+") just returns nil instead of crashing.
///
/// Supports: + - * / % ^, x or × for multiply, ÷ for divide, parentheses,
/// unary minus, sqrt(), and pi.
struct MathEvaluator {
    private let chars: [Character]
    private var pos = 0

    private init(_ input: String) {
        chars = Array(
            input.lowercased()
                .replacingOccurrences(of: "×", with: "*")
                .replacingOccurrences(of: "÷", with: "/")
                .replacingOccurrences(of: " ", with: "")
        )
    }

    static func evaluate(_ input: String) -> Double? {
        var parser = MathEvaluator(input)
        guard let value = parser.parseExpression(),
              parser.pos == parser.chars.count,   // reject trailing garbage
              value.isFinite else { return nil }
        return value
    }

    // expression = term (('+' | '-') term)*
    private mutating func parseExpression() -> Double? {
        guard var result = parseTerm() else { return nil }
        while pos < chars.count, chars[pos] == "+" || chars[pos] == "-" {
            let op = chars[pos]
            pos += 1
            guard let rhs = parseTerm() else { return nil }
            result = op == "+" ? result + rhs : result - rhs
        }
        return result
    }

    // term = unary (('*' | 'x' | '/' | '%') unary)*
    private mutating func parseTerm() -> Double? {
        guard var result = parseUnary() else { return nil }
        while pos < chars.count, "*x/%".contains(chars[pos]) {
            let op = chars[pos]
            pos += 1
            guard let rhs = parseUnary() else { return nil }
            switch op {
            case "/":
                guard rhs != 0 else { return nil }
                result /= rhs
            case "%":
                guard rhs != 0 else { return nil }
                result = result.truncatingRemainder(dividingBy: rhs)
            default:
                result *= rhs
            }
        }
        return result
    }

    // unary = '-' unary | power      (so -2^2 = -4, like a normal calculator)
    private mutating func parseUnary() -> Double? {
        if pos < chars.count, chars[pos] == "-" {
            pos += 1
            guard let value = parseUnary() else { return nil }
            return -value
        }
        return parsePower()
    }

    // power = primary ('^' unary)?   (right-associative: 2^3^2 = 2^9)
    private mutating func parsePower() -> Double? {
        guard let base = parsePrimary() else { return nil }
        if pos < chars.count, chars[pos] == "^" {
            pos += 1
            guard let exponent = parseUnary() else { return nil }
            return pow(base, exponent)
        }
        return base
    }

    // primary = number | '(' expression ')' | function '(' expression ')' | constant
    private mutating func parsePrimary() -> Double? {
        guard pos < chars.count else { return nil }

        if chars[pos] == "(" {
            pos += 1
            guard let value = parseExpression(),
                  pos < chars.count, chars[pos] == ")" else { return nil }
            pos += 1
            return value
        }

        if chars[pos].isLetter {
            var name = ""
            while pos < chars.count, chars[pos].isLetter {
                name.append(chars[pos])
                pos += 1
            }
            if name == "pi" { return .pi }
            guard pos < chars.count, chars[pos] == "(",
                  let arg = parsePrimary() else { return nil }
            switch name {
            case "sqrt": return arg >= 0 ? sqrt(arg) : nil
            default: return nil
            }
        }

        var number = ""
        while pos < chars.count, chars[pos].isASCII, chars[pos].isNumber || chars[pos] == "." {
            number.append(chars[pos])
            pos += 1
        }
        return Double(number)
    }
}